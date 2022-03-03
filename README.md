# Building Web Applications based on Amazon EKS

## Setting workspace

### AWS Cloud9
#### IDE configuration with AWS Cloud9
- Cloud9 console > Create environment > platform : Amazon Linux 2
- Create in a public subnet

#### Create IAM Role
- Create an IAM Role with Administrator access

#### Grant IAM Role to an AWS Cloud9 instance
- EC2 instnace console > Select AWS Cloud9 instance, Actions > Security > Modify IAM Role
- Change IAM role

#### Update IAM settings in IDE
- Disable AWS Cloud9 credentials. After that attach the IAM Role(because they are not compatible with EKS IAM authentication)
- Cloud9 IDE > AWS SETTINGS in the sidebar > Credentials > Disable the AWS managed temperature credits 
- Remove existing credential files 
```
rm -vf ${HOME}/.aws/credentials
```
- Check that Cloud9 IDE is using the correct IAM Role
```
aws sts get-caller-identity --query Arn | grep eks-admin
```

### AWS CLI
#### Update AWS CLI
```
sudo pip install --upgrade awscli
```
#### check the version
```
aws --version
```

### kubectl
#### Install kubectl
- Check to install the corresponding kubectl to the Amazon EKS version you want to deploy
  https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
```
sudo curl -o /usr/local/bin/kubectl  \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
```
```
sudo chmod +x /usr/local/bin/kubectl
```

### etc
#### Install jq
```
sudo yum install -y jq
```
#### Install bash-completion
```
sudo yum install -y bash-completion
```

### Install eksctl
#### Install eksctl
- Download the latest eksctl binary 
```
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
```
- Move the binary to the location /usr/local/bin
```
sudo mv -v /tmp/eksctl /usr/local/bin
```
- check the installation
```
eksctl version
```

### AWS Cloud9 Additional Settings
#### Set default value to AWS Region
```
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
    
aws configure set default.region ${AWS_REGION}
```
#### Register the account ID 
```
export ACCOUNT_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.accountId')

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
```

## Container Image
### Upload container image to Amazon ECR
#### Create Amazon ECR Repository and Upload Image
- Download the source code to be containerized 
```
git clone https://github.com/joozero/amazon-eks-flask.git
``` 

#### Create an image repository
```
aws ecr create-repository \
--repository-name demo-flask-backend \
--image-scanning-configuration scanOnPush=true \
--region ${AWS_REGION}
```

#### Bring the authentication token and push the container image to the repository
```
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com
```
