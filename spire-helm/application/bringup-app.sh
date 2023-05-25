#/bin/bash

CTX_CLUSTER1=kind-aws-cluster
CTX_CLUSTER2=kind-google-cluster

(cd greeter; make docker-build)

KIND_CLUSTER_NAME=aws-cluster kind load docker-image greeter-server:demo
KIND_CLUSTER_NAME=google-cluster kind load docker-image greeter-client:demo

kubectl config use-context ${CTX_CLUSTER1}
kubectl create ns greeter-server
kubectl -n greeter-server apply -k config/cluster1/greeter-server

GREETER_IP_PORT=$(./scripts/get_service_ip_port.sh greeter-server greeter-server)


kubectl config use-context ${CTX_CLUSTER2}

kubectl create ns greeter-client

kubectl -n greeter-client apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: greeter-client-config
data:
  greeter-server-addr: "$GREETER_IP_PORT"
EOF


kubectl -n greeter-client apply -k config/cluster2/greeter-client



kubectl config use-context ${CTX_CLUSTER1}
kubectl -n greeter-server apply -f config/greeter-server-id.yaml
#kubectl delete  clusterspiffeid  spire-aws-controller-manager-service-account-based

kubectl config use-context ${CTX_CLUSTER2}
kubectl -n greeter-client apply -f config/greeter-client-id.yaml
#kubectl delete  clusterspiffeid  spire-google-controller-manager-service-account-based

echo "correct the client cm with correct ip -> $GREETER_IP_PORT"
echo "kubectl -n greeter-client edit cm greeter-client-config"
