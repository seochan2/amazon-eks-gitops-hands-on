# 4. ArgoCD 
### 4.1. 생성
#### 4.1.1 ArgoCD 설치 & 네임스페이스 생성
```	
kubectl create namespace argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
```
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io created
serviceaccount/argocd-application-controller created
serviceaccount/argocd-applicationset-controller created
serviceaccount/argocd-dex-server created
serviceaccount/argocd-notifications-controller created
serviceaccount/argocd-redis created
serviceaccount/argocd-repo-server created
serviceaccount/argocd-server created
role.rbac.authorization.k8s.io/argocd-application-controller created
role.rbac.authorization.k8s.io/argocd-applicationset-controller created
role.rbac.authorization.k8s.io/argocd-dex-server created
role.rbac.authorization.k8s.io/argocd-notifications-controller created
role.rbac.authorization.k8s.io/argocd-server created
clusterrole.rbac.authorization.k8s.io/argocd-application-controller created
clusterrole.rbac.authorization.k8s.io/argocd-server created
rolebinding.rbac.authorization.k8s.io/argocd-application-controller created
rolebinding.rbac.authorization.k8s.io/argocd-applicationset-controller created
rolebinding.rbac.authorization.k8s.io/argocd-dex-server created
rolebinding.rbac.authorization.k8s.io/argocd-notifications-controller created
rolebinding.rbac.authorization.k8s.io/argocd-server created
clusterrolebinding.rbac.authorization.k8s.io/argocd-application-controller created
clusterrolebinding.rbac.authorization.k8s.io/argocd-server created
configmap/argocd-cm created
configmap/argocd-cmd-params-cm created
configmap/argocd-gpg-keys-cm created
configmap/argocd-notifications-cm created
configmap/argocd-rbac-cm created
configmap/argocd-ssh-known-hosts-cm created
configmap/argocd-tls-certs-cm created
secret/argocd-notifications-secret created
secret/argocd-secret created
service/argocd-applicationset-controller created
service/argocd-dex-server created
service/argocd-metrics created
service/argocd-notifications-controller-metrics created
service/argocd-redis created
service/argocd-repo-server created
service/argocd-server created
service/argocd-server-metrics created
deployment.apps/argocd-applicationset-controller created
deployment.apps/argocd-dex-server created
deployment.apps/argocd-notifications-controller created
deployment.apps/argocd-redis created
deployment.apps/argocd-repo-server created
deployment.apps/argocd-server created
statefulset.apps/argocd-application-controller created
networkpolicy.networking.k8s.io/argocd-application-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-applicationset-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-dex-server-network-policy created
networkpolicy.networking.k8s.io/argocd-notifications-controller-network-policy created
networkpolicy.networking.k8s.io/argocd-redis-network-policy created
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy created
networkpolicy.networking.k8s.io/argocd-server-network-policy created

namespace/argocd created
```
#### 4.1.2 접속
- 외부에서 ArgoCD에 접속하기 위한 CLB 생성
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```
```
service/argocd-server patched
```
- ArgoCD URL 주소 확인
```
export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output .status.loadBalancer.ingress[0].hostname`

echo $ARGOCD_SERVER
```
```
a7e3fd5d4e0dc48b3afdxxxxxxxxxxxx-xxxxxxxxxx.ap-southeast-2.elb.amazonaws.com
```
- 초기 admin 사용자 암호 확인
```
ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

echo $ARGO_PWD
```
- 서버 로그인		

#### 4.1.3 ArgoCD가 레포지토리에 접속할 수 있도록 IAM User 및 Git Credential 생성
- AWS Console > IAM > Users - Create user
```
 User details
		User name : eks-cicd-argo
	Set permissions
		Permissions options - Attach policies directly
			AWSCodeCommitPowerUser 
	Review and create
		Create user
	eks-cicd-argo 유저 선택 > Security credentials > HTTPS Git credentials for AWS CodeCommit - Generate credentials		
```

#### 4.1.4 Manifest Repository 연동
```
AgroCD > Settings > Repositories > Connect repo 
    Choose your connection method: : https 방식 
	Project : default
	Repository URL : https://git-codecommit.ap-southeast-2.amazonaws.com/v1/repos/gitops-k8s
	Username / Password : 4.1.3에서 생성한 정보 입력
	Connect 선택
```

#### 4.1.5 Application Repository 연동    
```
AgroCD > Applications > New App
    Applications : gitops-app
	Project : default
	Repository URL : https://git-codecommit.ap-southeast-2.amazonaws.com/v1/repos/gitops-k8s
	path : ./
	Cluster URL : https://kubernetes.default.svc
    Namespace : gitops-app
Create 선택
SYNC 클릭
```
	
#### 4.1.6 Sync 실행
