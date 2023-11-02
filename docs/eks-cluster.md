# 2. EKS 클러스터 생성
### 2.1 관련 소스 다운로드
- Git Clone을 통한 소스 다운로드
```
git clone https://github.com/seochan2/amazon-eks-gitops-hands-on.git

```
- 작업 폴더 이동
```
cd amazon-eks-gitops-hands-on

cd terraform
```
### 2.2 Terraform을 통한 EKS 클러스터 생성
#### 2.2.1 Terraform 작업
- 초기화
```
terraform init
```
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
- 계획 
```
terraform plan 
```
```
Plan: 90 to add, 0 to change, 0 to destroy.
```
- 적용
```
terraform apply
```
```
Apply complete! Resources: 90 added, 0 changed, 0 destroyed.

Outputs:

public_subnets = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-xxxxxxxxxxxxxxxxx",
]
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
```

#### 2.2.2 클러스터 확인
- 생성한 EKS 클러스터 접속을 위한 kubeconfig 설정
```
aws eks update-kubeconfig --region ap-southeast-2 --name gitops-cluster
```
```
Added new context arn:aws:eks:ap-southeast-2:xxxxxxxxxxxx:cluster/gitops-cluster to /home/ec2-user/.kube/config
```
- 노드가 제대로 배포되었는지 확인
```
kubectl get nodes 
```
```
NAME                                             STATUS   ROLES    AGE   VERSION
ip-10-0-10-113.ap-southeast-2.compute.internal   Ready    <none>   73m   v1.28.1-eks-43840fb
ip-10-0-20-226.ap-southeast-2.compute.internal   Ready    <none>   74m   v1.28.1-eks-43840fb
```
