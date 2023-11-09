# 5. Clean up resources
### 5.1 ArgoCD 삭제
```
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
```
Warning: deleting cluster-scoped resources, not scoped to the provided namespace
customresourcedefinition.apiextensions.k8s.io "applications.argoproj.io" deleted
customresourcedefinition.apiextensions.k8s.io "applicationsets.argoproj.io" deleted
customresourcedefinition.apiextensions.k8s.io "appprojects.argoproj.io" deleted
serviceaccount "argocd-application-controller" deleted
serviceaccount "argocd-applicationset-controller" deleted
serviceaccount "argocd-dex-server" deleted
serviceaccount "argocd-notifications-controller" deleted
serviceaccount "argocd-redis" deleted
serviceaccount "argocd-repo-server" deleted
serviceaccount "argocd-server" deleted
role.rbac.authorization.k8s.io "argocd-application-controller" deleted
role.rbac.authorization.k8s.io "argocd-applicationset-controller" deleted
role.rbac.authorization.k8s.io "argocd-dex-server" deleted
role.rbac.authorization.k8s.io "argocd-notifications-controller" deleted
role.rbac.authorization.k8s.io "argocd-server" deleted
clusterrole.rbac.authorization.k8s.io "argocd-application-controller" deleted
clusterrole.rbac.authorization.k8s.io "argocd-server" deleted
rolebinding.rbac.authorization.k8s.io "argocd-application-controller" deleted
rolebinding.rbac.authorization.k8s.io "argocd-applicationset-controller" deleted
rolebinding.rbac.authorization.k8s.io "argocd-dex-server" deleted
rolebinding.rbac.authorization.k8s.io "argocd-notifications-controller" deleted
rolebinding.rbac.authorization.k8s.io "argocd-server" deleted
clusterrolebinding.rbac.authorization.k8s.io "argocd-application-controller" deleted
clusterrolebinding.rbac.authorization.k8s.io "argocd-server" deleted
configmap "argocd-cm" deleted
configmap "argocd-cmd-params-cm" deleted
configmap "argocd-gpg-keys-cm" deleted
configmap "argocd-notifications-cm" deleted
configmap "argocd-rbac-cm" deleted
configmap "argocd-ssh-known-hosts-cm" deleted
configmap "argocd-tls-certs-cm" deleted
secret "argocd-notifications-secret" deleted
secret "argocd-secret" deleted
service "argocd-applicationset-controller" deleted
service "argocd-dex-server" deleted
service "argocd-metrics" deleted
service "argocd-notifications-controller-metrics" deleted
service "argocd-redis" deleted
service "argocd-repo-server" deleted
service "argocd-server" deleted
service "argocd-server-metrics" deleted
deployment.apps "argocd-applicationset-controller" deleted
deployment.apps "argocd-dex-server" deleted
deployment.apps "argocd-notifications-controller" deleted
deployment.apps "argocd-redis" deleted
deployment.apps "argocd-repo-server" deleted
deployment.apps "argocd-server" deleted
statefulset.apps "argocd-application-controller" deleted
networkpolicy.networking.k8s.io "argocd-application-controller-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-applicationset-controller-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-dex-server-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-notifications-controller-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-redis-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-repo-server-network-policy" deleted
networkpolicy.networking.k8s.io "argocd-server-network-policy" deleted
```
### 5.2 ECR에서 등록된 이미지 전체 수동 삭제
- AWS Console > Amazon ECR > Repositories
 Repository 선택후 Delete 버튼 클릭

### 5.3 terraform 삭제
```
terraform destroy --auto-approve
```
