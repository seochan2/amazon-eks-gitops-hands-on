# 1. 실습 환경 구축

### 1.1 AWS Cloud9 구성
#### 1.1.1 VPC 생성 - 리전별 기본 VPC 사용시, 생략략
- AWS Console > VPC > Create VPC > VPC Setting
- Resources to create : VPC and more
- Name tag auto-generation : eks-cloud
- IPv4 CIDR block : 기본값(10.1.0.0/16)
- IPv6 CIDR block : No IPv6 CIDR block
- Tenancy : 기본값(Default)
- Number of Availability Zones (AZs) : 1
- Number of public subnets : 1
- Number of private subnets : 0
- NAT gateways ($) : 없음
- VPC endpoints : 기본값(S3 Gateway)
- DNS options : 기본값(Enable DNS hostnames / Enable DNS resolution)
- Additional tags - Add new tag : Key (UserType) , Value(eks-cloud9) 
- Create VPC

#### 1.1.2 AWS Cloud9으로 IDE 구성
Cloud9 기반의 실습 환경 구축
- AWS Console > Cloud9 > Create environment
- Name 입력 : eks-workspace-<닉네임> (ex, eks-workspace-scp)
- Environment type : 기본값(New EC2 instance)
- Instance Type : t3.small
- Platform : 기본값(Amazon Linux 2)
- Timeout : 기본값(30 minutes)
- Connection : Secure Shell(SSH)
- VPC Setting : Amazon Virtual Private Cloud (VPC) : 1.1.1에서 생성한 VPC / Subnet : public Subnet 선택(eks-subnet-public~)
- Create 

#### 1.1.3 IAM Role 생성
Administrator access 정책을 가진 IAM Role을 생성
- AWS Console > IAM > ROLE > Create Role
- Trusted entity type : AWS service
- Use case : EC2 > Next
- AdministratorAccess 검색후 선택 > Next
- Role Name : eksworkspace-admin-<닉네임> (ex. eksworkspace-admin-scp) / Role Name에 "." 주의
- Create Role

#### 1.1.4 AWS Cloud9 Instance에 IAM Role 부여
실습 환경에 Admin 권한 부여 
- EC2 instnace console > Select AWS Cloud9 instance (aws-cloud9-eks-workspace-44178fc24ede445193e90242705c4c11 형식)
- Actions > Security > Modify IAM Role 선택
- Change IAM role 리스트에서 1.1.3에서 생성한 Role Name(ex. eksworkspace-admin-scp) 선택
- Update IAM role

#### 1.1.5 IDE에서 IAM 설정 업데이트
Cloud9의 기본 IAM credentials은 동적으로 관리되고(15분 간격으로 refresh),  EKS IAM authentication과 호환되지 않기에 이를 비활성화하고 IAM Role을 붙임
- Cloud9 IDE > 우측 상단 기어 아이콘 클릭 > Preferences > AWS Setting - Disable the AWS managed temperature credits 

- 기존의 자격 증명 파일도 제거(선택)
```
rm -vf ${HOME}/.aws/credentials
```
- Cloud9 IDE가 올바른 IAM Role을 사용하고 있는지 확인
```
aws sts get-caller-identity --query Arn | grep eks-workspace-admin-<닉네임>
```
- 결과 예시   
`arn:aws:sts::876630244803:assumed-role/eksworkspace-admin-scp/i-03e9af70279e891de`


### 1.2 AWS CLI
#### 1.2.1 AWS CLI 1.x 버전 삭제
```
sudo rm /usr/bin/aws

sudo rm /usr/bin/aws_completer

sudo rm -rf /usr/local/aws-cli
```

#### 1.2.2 AWS CLI 2.x 버전 설치
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install

export PATH=/usr/local/bin:$PATH

source ~/.bash_profile
```

#### 1.2.3 버전 확인 (2.x대 버전)
```
aws --version
```
- 결과 예시   
`aws-cli/2.13.28 Python/3.11.6 Linux/5.10.196-185.743.amzn2.x86_64 exe/x86_64.amzn.2 prompt/off`

### 1.3 kubectl
#### 1.3.1 kubectl 최신 바이너리 다운로드
[설치 페이지](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html)를 참조하여, 배포할 Amazon EKS 버전과 상응하는 kubectl를 설치(최신버전 : 2023-11-01 기준, 1.28.1)
```
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.28.1/2023-09-14/bin/linux/amd64/kubectl
```

#### 1.3.2 바이너리 실행 권한 적용 및 패스 설정
```
chmod +x ./kubectl

mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH

echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
```

#### 1.3.3 버전 확인
```
kubectl version --client
```
- 결과 예시   
`Client Version: v1.28.1-eks-43840fb`
`Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3`

### 1.4 terraform
#### 1.4.1 terraform 설치
```
sudo yum install -y yum-utils

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

sudo yum -y install terraform
```

#### 1.4.2 enable tab completion 
```
touch ~/.bashrc

terraform -install-autocomplete
```

#### 1.4.3 버전 확인
```
terraform version
```
- 결과 예시   
`Terraform v1.6.2`
`on linux_amd64`


### 1.5 기타 툴
#### 1.5.1 jq 설치
JSON 형식의 데이터를 다루는 커맨드라인 유틸리티
```
sudo yum install -y jq
```

#### 1.5.2 bash-completion 설치
kubectl 명령어의 자동 완성 지원
```
sudo yum install -y bash-completion
```

#### 1.5.3 K9s 설치
터미널에서 Kubernetes 클러스터를 관리할 수 있는 CLI 도구구
```
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')

curl -sL https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | sudo tar xfz - -C /usr/local/bin k9s
```
#### 1.5.3.1 버전 확인
```
k9s version
```
- 결과 예시   
`  ____  __.________      `   
`|    |/ _/   __   \______`   
`|      < \____    /  ___/`   
`|    |  \   /    /\___ \ `   
`|____|__ \ /____//____  >`   
`        \/            \/ `   
`Version:    v0.27.4`   
`Commit:     f4543e9bd2f9e2db922d12ba23363f6f7db38f9c`   
`Date:       2023-05-07T16:55:34Z`

### 1.6 Cloud9 추가 설정

#### 1.6.1 Cloud9 디스크 사이즈 증설
```
wget https://gist.githubusercontent.com/joozero/b48ee68e2174a4f1ead93aaf2b582090/raw/2dda79390a10328df66e5f6162846017c682bef5/resize.sh

sh resize.sh
```

#### 1.6.1.1 결과 확인
```
df -h
```
- 결과 예시   
`Filesystem      Size  Used Avail Use% Mounted on`   
`devtmpfs        3.8G     0  3.8G   0% /dev`   
`tmpfs           3.8G     0  3.8G   0% /dev/shm`   
`tmpfs           3.8G  460K  3.8G   1% /run`   
`tmpfs           3.8G     0  3.8G   0% /sys/fs/cgroup`   
`/dev/nvme0n1p1   30G  7.1G   23G  24% /`   
`tmpfs           776M     0  776M   0% /run/user/1000`   
