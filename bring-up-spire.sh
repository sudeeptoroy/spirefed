#/bin/bash

set -e

kubectl config use-context ${CTX_CLUSTER1}

kubectl create ns istio-system
kubectl create ns spire
kubectl apply -f ./spire/configmaps.yaml

(cd spire ; ./deploy-spire-domain-aws.sh)

kubectl -n spire rollout status statefulset spire-server
kubectl -n spire rollout status daemonset spire-agent

aws_bundle=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

kubectl config use-context ${CTX_CLUSTER2}

kubectl create ns istio-system
kubectl create ns spire
kubectl apply -f ./spire/configmaps.yaml

(cd spire ; ./deploy-spire-domain-google.sh)

kubectl -n spire rollout status statefulset spire-server
kubectl -n spire rollout status daemonset spire-agent

google_bundle=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

# Set example.org bundle to domain.test SPIRE bundle endpoint
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server  bundle set -format spiffe -id spiffe://aws.com -socketPath /run/spire/sockets/server.sock <<< "$aws_bundle"

### move to cluster 1
kubectl config use-context ${CTX_CLUSTER1}

# Set domain.test bundle to example.org SPIRE bundle endpoint
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server  bundle set -format spiffe -id spiffe://google.com -socketPath /run/spire/sockets/server.sock <<< "$google_bundle"


