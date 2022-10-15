#/bin/bash

kubectl config use-context $CTX_CLUSTER1
(cd istio ; ./deploy-istio-aws.sh)

kubectl config use-context $CTX_CLUSTER2
(cd istio ; ./deploy-istio-google.sh)


# note, update the below ips with  pod ips
# 1. k -n kube-system get pod -owide --context="${CTX_CLUSTER1}" | grep api
# 1. k -n kube-system get pod -owide --context="${CTX_CLUSTER2}" | grep api

#APISERVER_IP_AWS=$(kubectl -n kube-system get pod -owide --context="${CTX_CLUSTER1}" -o=jsonpath='{.items[?(@.metadata.labels.component=="kube-apiserver")].status.podIP}')
#APISERVER_IP_GOOGLE=$(kubectl -n kube-system get pod -owide --context="${CTX_CLUSTER1}" -o=jsonpath='{.items[?(@.metadata.labels.component=="kube-apiserver")].status.podIP}')

istioctl x create-remote-secret --context="${CTX_CLUSTER1}" --name=aws-cluster --server=https://aws-cluster-control-plane:6443 | kubectl apply -f - --context="${CTX_CLUSTER2}"

istioctl x create-remote-secret --context="${CTX_CLUSTER2}" --name=google-cluster --server=https://google-cluster-control-plane:6443 | kubectl apply -f - --context="${CTX_CLUSTER1}"
