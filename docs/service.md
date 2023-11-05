# 3. Service
### 3.1 Git 설정
- Global 변수 설정
```
git config --global user.name "<Name>"
```
```
git config --global user.email "<Email>"
```
- 확인
```
git config -l
```
### 3.2 Repository 업데이트
#### 3.2.1 Manifest Repository
- Manifest Repository 폴더로 이동
```
cd ~/environment/amazon-eks-gitops-hands-on/eks-gitops-k8s
```
- service.yaml 파일내 subnets 정보를 현재 Subnet 정보로 업데이트
```
service.yaml 파일내 line 31
```
- 소스 commmit
```
git init 
```
```
git remote add origin https://git-codecommit.ap-southeast-2.amazonaws.com/v1/repos/gitops-k8s

git branch -m master main
```
```
git add .

git commit -m "init commit"

git push origin main
```

#### 3.2.2 Application Repository
- Application Repository 폴더로 이동
```
cd ~/environment/amazon-eks-gitops-hands-on/eks-gitops-app
```
- 소스 commmit
```
git init 
```
```
git remote add origin https://git-codecommit.ap-southeast-2.amazonaws.com/v1/repos/gitops-app

git branch -m master main
```
``` 
git add .

git commit -m "init commit"

git push origin main
```

#### 3.2.3 CodeBuild 결과 확인
