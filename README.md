after deploying the kind clusters 

run the below commands and the node ip address
k get node -owide --context="${CTX_CLUSTER1}"
k get node -owide --context="${CTX_CLUSTER2}"

update the below files accordingly

spire/server-configmap-google.yaml   >> update ip to aws clusters node ip
spire/server-configmap-aws.yaml >> update ip to google clusters node ip


k -n kube-system get pod -owide --context="${CTX_CLUSTER1}" | grep api
k -n kube-system get pod -owide --context="${CTX_CLUSTER2}" | grep api

update istio/bring-up.sh to reference the right ips for the api servers
