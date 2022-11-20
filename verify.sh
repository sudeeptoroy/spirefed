#/bin/bash

export CTX_CLUSTER1=kind-aws-cluster
export CTX_CLUSTER2=kind-google-cluster

kubectl create --context="${CTX_CLUSTER1}" namespace sleep
kubectl create --context="${CTX_CLUSTER1}" namespace helloworld
kubectl create --context="${CTX_CLUSTER2}" namespace sleep
kubectl create --context="${CTX_CLUSTER2}" namespace helloworld

kubectl label --context="${CTX_CLUSTER1}" namespace sleep \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER1}" namespace helloworld \
    istio-injection=enabled

kubectl label --context="${CTX_CLUSTER2}" namespace sleep \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace helloworld \
    istio-injection=enabled

kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/helloworld-aws.yaml \
    -l service=helloworld -n helloworld
kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/helloworld-google.yaml \
    -l service=helloworld -n helloworld

kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/helloworld-aws.yaml -n helloworld

kubectl -n helloworld --context="${CTX_CLUSTER1}" rollout status deploy helloworld-v1
kubectl -n helloworld get pod --context="${CTX_CLUSTER1}" -l app=helloworld

kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/helloworld-google.yaml -n helloworld

kubectl -n helloworld  --context="${CTX_CLUSTER2}" rollout status deploy helloworld-v2
kubectl -n helloworld get pod --context="${CTX_CLUSTER2}" -l app=helloworld


kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/sleep-aws.yaml -n sleep
kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/sleep-google.yaml -n sleep

kubectl -n sleep  --context="${CTX_CLUSTER1}" rollout status deploy sleep
kubectl -n sleep get pod --context="${CTX_CLUSTER1}" -l app=sleep

kubectl -n sleep  --context="${CTX_CLUSTER2}" rollout status deploy sleep
kubectl -n sleep get pod --context="${CTX_CLUSTER2}" -l app=sleep

#### testing now
echo "###############################################################"
echo "###############################################################"
echo "                          TESTING"
echo "###############################################################"
echo "###############################################################"
echo ""

echo ">>> curl hellowold end point to see if they are up"
echo ""

kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.helloworld:5000/hello

kubectl exec --context="${CTX_CLUSTER2}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.helloworld:5000/hello

echo ""
echo " >>> All the pods are running and accessible, scalling the local helloworld-v1 to 0, so that the curl command can reach the other pod in the other cluster"
echo ""
echo ""

kubectl -n helloworld scale deploy helloworld-v1 --context="${CTX_CLUSTER1}" --replicas 0
sleep 2

echo ""
echo ">>> curling helloworld, it should reach the other cluster"
echo ""

kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.helloworld:5000/hello

sleep 2

echo ""
echo "configuring auth policy"
echo ""

kubectl apply --context="${CTX_CLUSTER1}" \
    -f helloworld/auth-policy-aws.yaml -n helloworld
kubectl apply --context="${CTX_CLUSTER2}" \
    -f helloworld/auth-policy-google.yaml -n helloworld

sleep 2

echo ""
echo "curl the helloworld@google from sleep@aws"
echo ""


kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.helloworld:5000/hello

echo ""
echo ""
echo ">>> run the below command to test it manually"
echo ""

echo "
kubectl exec --context="${CTX_CLUSTER1}" -n sleep -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sleep -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.helloworld:5000/hello
"
