locals {
  name       = "gitops"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  
  tags = {
    TerraformManaged = true
  }
}

module "ci" {
  source = "./modules/ci"

  # PREFIX
  prefix = local.name
  # ENVIRONMENT PREFIX
  env = "stg"

  # IMAGE CODECOMMIT REPOSITORY NAME
  codecommit_repository_for_image = "${local.name}-app"
  # BRANCH NAME
  branch_name = "main"
  # ECR REPOSITORY NAME
  ecr_name = "${local.name}-app"

  # K8S CODECOMMIT REPOSITORY NAME
  codecommit_repository_for_k8s = "${local.name}-k8s"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.name}-vpc"
  cidr = "10.0.0.0/16"

  azs                 = ["ap-southeast-2a", "ap-southeast-2b"]
  public_subnets      = ["10.0.10.0/24", "10.0.20.0/24"]
  public_subnet_names = ["gitops-public-subnet-2a", "gitops-public-subnet-2b"]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 # 해당 태그 지정 시, k8s 내에서 ingress 생성 시 서브넷 자동 지정
  }

  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true # 퍼블릭 서브넷 내 생성되는 리소스에 자동으로 퍼블릭 IP를 할당한다.

  tags = {
    TerraformManaged = true
  }
}

# Terraform에서 k8s에 접근할 수 있도록 인증 정보를 제공한다.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
# Terraform에서 helm을 통해 k8s 내 Add-on를 설치할 수 있도록 인증 정보를 제공한다.
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

data "aws_availability_zones" "available" {}

# Terraform에서 AWS의 계정 ID를 참조하기 위해 정의한다. 사용은 ${data.aws_caller_identity.current.account_id}
data "aws_caller_identity" "current" {}

# EKS 클러스터와 통신하기 위한 인증 토큰을 가져온다.
data "aws_eks_cluster_auth" "eks" { name = module.eks.cluster_name }

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                   = "${local.name}-cluster"
  cluster_version                = 1.28
  cluster_endpoint_public_access = true

  # EKS Add-On 정의
  cluster_addons = {
    coredns = {
      most_recent                 = true
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent                 = true
      before_compute              = true # 워커 노드가 프로비저닝되기 전 vpc-cni가 배포되어야한다. 배포 전 워커 노드가 프로비저닝 되면 파드 IP 할당 이슈 발생
      resolve_conflicts = "OVERWRITE"
      service_account_role_arn    = module.vpc_cni_irsa_role.iam_role_arn # IRSA(k8s ServiceAccount에 IAM 역할을 사용한다)
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true" # prefix assignment mode 활성화
          WARM_PREFIX_TARGET       = "1"    # 기본 권장 값
        }
      })
    }
  }

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  # aws-auth configmap
  manage_aws_auth_configmap = true # AWS -> EKS 접근을위한 configmap 자동 생성

  # 관리형 노드그룹에 사용할 공통 사항 정의
  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
    instance_types             = ["t3.medium"]
    capacity_type              = "ON_DEMAND"
    iam_role_attach_cni_policy = true
    use_name_prefix            = false # false하지 않으면 리소스 이름 뒤 임의의 난수값이 추가되어 생성됨
    use_custom_launch_template = false # AWS EKS 관리 노드 그룹에서 제공하는 기본 템플릿을 사용
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 20
          volume_type           = "gp3"
          delete_on_termination = true
        }
      }
    }
    remote_access = { # Remote access cannot be specified with a launch template
      ec2_ssh_key               = module.key_pair.key_pair_name
      source_security_group_ids = [aws_security_group.remote_access.id]
      tags = {
        "kubernetes.io/cluster/${local.name}-eks-cluster" = "owned" # AWS LB Controller 사용을 위한 요구 사항
      }
    }

    tags = local.tags
  }

  # 관리형 노드 그룹 정의
  eks_managed_node_groups = {
    gitops-eks-app-ng = {
      name = "${local.name}-app-ng"
      labels = {
        nodegroup = "app"
      }
      desired_size = 1
      min_size     = 1
      max_size     = 1
    }

    gitops-eks-mgmt-ng = {
      name = "${local.name}-mgmt-ng"
      labels = {
        nodegroup = "mgmt"
      }
      desired_size = 1
      min_size     = 1
      max_size     = 1
    }
  }
}

# 각종 Add-on에 필요한 IRSA 생성해주는 모듈
# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/master/modules/iam-role-for-service-accounts-eks
module "vpc_cni_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${local.name}-vpc-cni-irsa-role"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = local.tags
}

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${local.name}-lb-controller-irsa-role"
  attach_load_balancer_controller_policy = true # 이 Input을 기준으로 목적에 맞는 Role이 생성됨.

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

module "load_balancer_controller_targetgroup_binding_only_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                                                       = "${local.name}-lb-controller-tg-binding-only-irsa-role"
  attach_load_balancer_controller_targetgroup_binding_only_policy = true # 이 Input을 기준으로 목적에 맞는 Role이 생성됨.

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = local.tags
}

module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name_prefix    = "${local.name}-cluster"
  create_private_key = true
}

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-cluster-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "kubernetes_service_account" "aws-load-balancer-controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa_role.iam_role_arn # irsa 생성 모듈에서 output으로 iam_role_arn을 제공한다.
    }

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }

  }

  depends_on = [module.load_balancer_controller_irsa_role]
}

### Helm
# https://github.com/GSA/terraform-kubernetes-aws-load-balancer-controller/blob/main/main.tf
# https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.5/
resource "helm_release" "aws-load-balancer-controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = false
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  #depends_on = [kubernetes_service_account.aws-load-balancer-controller]
}
