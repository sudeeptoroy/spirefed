#!/bin/bash

set -e

# bring up kind cluster 1
kind create cluster --config=kind-c1.yaml

# bring up kind cluster 2
kind create cluster --config=kind-c2.yaml

# install LB for the east west gw
kubectl apply -f metallb.yaml --context=kind-aws
kubectl apply -f metallb.yaml --context=kind-google

#In order to complete the configuration, we need to provide a range of IP addresses MetalLB controls. We want this range to be on the docker kind network
docker network inspect -f '{{.IPAM.Config}}' kind

kubectl apply -f metallb-cm-c1.yaml --context kind-aws
kubectl apply -f metallb-cm-c2.yaml --context kind-google

# istio
#export ISTIO_HOME=<path the istio>
# create certs and move it here

export CTX_CLUSTER1=kind-aws
export CTX_CLUSTER2=kind-google

k --context $CTX_CLUSTER1 create ns istio-system
k --context $CTX_CLUSTER2 create ns istio-system

kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1

kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2

kubectl --context="${CTX_CLUSTER1}" create secret generic cacerts -n istio-system \
     --from-file=certs/cluster1/ca-cert.pem \
     --from-file=certs/cluster1/ca-key.pem \
     --from-file=certs/cluster1/root-cert.pem \
     --from-file=certs/cluster1/cert-chain.pem


kubectl --context="${CTX_CLUSTER2}" create secret generic cacerts -n istio-system \
     --from-file=certs/cluster2/ca-cert.pem \
     --from-file=certs/cluster2/ca-key.pem \
     --from-file=certs/cluster2/root-cert.pem \
     --from-file=certs/cluster2/cert-chain.pem

istioctl install --context="${CTX_CLUSTER1}" -y -f istio-aws.yaml

istioctl install --context="${CTX_CLUSTER2}" -y -f istio-google.yaml

#istioctl install -f istio-c1.yaml --context "${CTX_CLUSTER1}"
#istioctl install -f istio-c2.yaml --context "${CTX_CLUSTER2}"

kubectl apply -f istio-ew-gw.yaml --context "${CTX_CLUSTER1}"
kubectl apply -f istio-ew-gw.yaml --context "${CTX_CLUSTER2}"

istioctl x create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=aws \
  --server=https://172.18.0.3:6443 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"

istioctl x create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=google \
  --server=https://172.18.0.5:6443 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"


#istioctl x create-remote-secret \
#  --context="${CTX_CLUSTER1}" \
#  --name=kind-c1 | \
#  kubectl apply -f - --context="${CTX_CLUSTER2}"
#
#istioctl x create-remote-secret \
#  --context="${CTX_CLUSTER2}" \
#  --name=kind-c2 | \
#  kubectl apply -f - --context="${CTX_CLUSTER1}"

# Before applying generated secrets we need to change the address of the cluster. Instead of localhost and dynamically generated port, we have to use c1-control-plane:6443 for the first cluster, and respectively c2-control-plane:6443 for the second cluster

#istioctl x create-remote-secret   --context="${CTX_CLUSTER1}"   --name=kind-c1 --server=https://c1-control-plane:6443 | kubectl apply -f - --context="${CTX_CLUSTER2}"

#istioctl x create-remote-secret   --context="${CTX_CLUSTER2}"   --name=kind-c2 --server=https://c2-control-plane:6443 | kubectl apply -f - --context="${CTX_CLUSTER1}"

# verify

kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample



##
#APP

kubectl --context kind-c1 create ns busybox
kubectl --context kind-c1 create ns nginx
kubectl --context kind-c2 create ns nginx

kubectl --context kind-c1 label namespace busybox istio-injection=enabled
kubectl --context kind-c1 label namespace nginx istio-injection=enabled
kubectl --context kind-c2 label namespace nginx istio-injection=enabled



#####################################

# two TD


kubectl --context="${CTX_CLUSTER1}" delete secret cacerts -n istio-system
kubectl --context="${CTX_CLUSTER2}" delete secret cacerts -n istio-system

kubectl --context="${CTX_CLUSTER1}" create secret generic cacerts -n istio-system \
      --from-file=kind-c1/ca-cert.pem \
      --from-file=kind-c1/ca-key.pem \
      --from-file=kind-c1/root-cert.pem \
      --from-file=kind-c1/cert-chain.pem

kubectl --context="${CTX_CLUSTER2}" create secret generic cacerts -n istio-system \
      --from-file=kind-c2/ca-cert.pem \
      --from-file=kind-c2/ca-key.pem \
      --from-file=kind-c2/root-cert.pem \
      --from-file=kind-c2/cert-chain.pem


istioctl install -f istio-c1-two-td.yaml --context "${CTX_CLUSTER1}"
istioctl install -f istio-c2-two-td.yaml --context "${CTX_CLUSTER2}"

