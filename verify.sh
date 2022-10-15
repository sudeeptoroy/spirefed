#/bin/bash

kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample

kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled

kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/helloworld.yaml \
    -l service=helloworld -n sample

kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/helloworld.yaml \
    -l version=v1 -n sample

kubectl -n sample --context="${CTX_CLUSTER1}" rollout status deploy helloworld-v1
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld

kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/helloworld.yaml \
    -l version=v2 -n sample

kubectl -n sample  --context="${CTX_CLUSTER2}" rollout status deploy helloworld-v2
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld


kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/sleep-aws.yaml -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/sleep-google.yaml -n sample

kubectl -n sample  --context="${CTX_CLUSTER1}" rollout status deploy sleep
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep

kubectl -n sample  --context="${CTX_CLUSTER2}" rollout status deploy sleep
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep

#### testing now
echo "###############################################################"
echo "###############################################################"
echo "                          TESTING"
echo "###############################################################"
echo "###############################################################"
echo ""

echo ">>> curl hellowold end point to see if they are up"
echo ""

kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

echo ""
echo " >>> All the pods are running and accessible, scalling the local helloworld-v1 to 0, so that the curl command can reach the other pod in the other cluster"
echo ""
echo ""

kubectl -n sample scale deploy helloworld-v1 --context="${CTX_CLUSTER1}" --replicas 0
sleep 2

echo ""
echo ">>> curling helloworld, it should reach the other cluster"
echo ""

kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello

echo ""
echo ""
echo ">>> run the below command to test it manually"
echo ""

echo "
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
"
