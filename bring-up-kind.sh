#!/bin/bash

set -e

# bring up kind cluster 1
kind create cluster --config=kind/kind-aws.yaml

# bring up kind cluster 2
kind create cluster --config=kind/kind-google.yaml

export CTX_CLUSTER1=kind-aws-cluster
export CTX_CLUSTER2=kind-google-cluster

echo"
CTX_CLUSTER1=kind-aws-cluster
CTX_CLUSTER2=kind-google-cluster
CLUSTER1=$CTX_CLUSTER1
CLUSTER2=$CTX_CLUSTER2
"

# install LB for the east west gw
kubectl apply -f kind/metallb.yaml --context=$CTX_CLUSTER1
kubectl apply -f kind/metallb.yaml --context=$CTX_CLUSTER2

#In order to complete the configuration, we need to provide a range of IP addresses MetalLB controls. We want this range to be on the docker kind network
docker network inspect -f '{{.IPAM.Config}}' kind

kubectl apply -f kind/metallb-cm-aws.yaml --context $CTX_CLUSTER1
kubectl apply -f kind/metallb-cm-google.yaml --context $CTX_CLUSTER2
