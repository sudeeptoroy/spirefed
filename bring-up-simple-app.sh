
#/bin/bash

set -e

CTX_CLUSTER1=kind-aws-cluster
CTX_CLUSTER2=kind-google-cluster

( cd spire-helm/application; ./bringup-app.sh )
