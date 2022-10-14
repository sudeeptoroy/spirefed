#/bin/bash


CLUSTER1=${CTX_CLUSTER1}
CLUSTER2=${CTX_CLUSTER2}

kubectl config use-context $CLUSTER1
(cd istio ; ./deploy-istio-aws.sh)

kubectl config use-context $CLUSTER2
(cd istio ; ./deploy-istio-google.sh)


# note, update the below ips with  pod ips
# 1. k -n kube-system get pod -owide --context="${CLUSTER1}" | grep api
# 1. k -n kube-system get pod -owide --context="${CLUSTER2}" | grep api

istioctl x create-remote-secret --context="${CLUSTER1}" --name=aws-cluster --server=https://172.18.0.3:6443 | kubectl apply -f - --context="${CLUSTER2}"

istioctl x create-remote-secret --context="${CLUSTER2}" --name=google-cluster --server=https://172.18.0.5:6443 | kubectl apply -f - --context="${CLUSTER1}"
