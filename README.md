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
