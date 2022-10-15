#/bin/bash

export CTX_CLUSTER1=kind-aws-cluster
export CTX_CLUSTER2=kind-google-cluster

./bring-up-kind.sh
sleep 5
./bring-up-spire.sh
sleep 5
./bring-up-istio.sh

echo "#################"
echo " >> you can run 'verify.sh' to test now\n"
echo "#################"

#NP_AWS=$(kubectl get node -owide --context="${CTX_CLUSTER1}" -o=jsonpath='{.items[1].status.addresses[0].address}')
#NP_GOOGLE=$(kubectl get node -owide --context="${CTX_CLUSTER2}" -o=jsonpath='{.items[1].status.addresses[0].address}')
#
#echo "
#update the following files with these ip address:
#FILE: spire/server-configmap-aws.yaml
#IP: $NP_GOOGLE
#FILE: spire/server-configmap-google.yaml
#IP: $NP_AWS
#"

