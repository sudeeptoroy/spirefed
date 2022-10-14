#/bin/bash

CLUSTER1=${CTX_CLUSTER1}
CLUSTER2=${CTX_CLUSTER2}

kubectl create --context="${CLUSTER1}" namespace sample
kubectl create --context="${CLUSTER2}" namespace sample

kubectl label --context="${CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CLUSTER2}" namespace sample \
    istio-injection=enabled

kubectl apply --context="${CLUSTER1}" \
    -f helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CLUSTER2}" \
    -f helloworld/helloworld.yaml \
    -l service=helloworld -n sample

kubectl apply --context="${CLUSTER1}" \
    -f helloworld/helloworld.yaml \
    -l version=v1 -n sample

kubectl get pod --context="${CLUSTER1}" -n sample -l app=helloworld -w

kubectl apply --context="${CLUSTER2}" \
    -f helloworld/helloworld.yaml \
    -l version=v2 -n sample

kubectl get pod --context="${CLUSTER2}" -n sample -l app=helloworld -w


kubectl apply --context="${CLUSTER1}" \
    -f helloworld/sleep-aws.yaml -n sample
kubectl apply --context="${CLUSTER2}" \
    -f helloworld/sleep-google.yaml -n sample


kubectl get pod --context="${CLUSTER1}" -n sample -l app=sleep -w

kubectl get pod --context="${CLUSTER2}" -n sample -l app=sleep -w

#### testing now
echo "
kubectl exec --context="${CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

kubectl exec --context="${CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

 k -n sample scale deploy helloworld-v1 --context="${CLUSTER1}" --replicas 0
"


