#helm repo add spiffe https://spiffe.github.io/helm-charts/
#helm repo update
CTX_CLUSTER1=kind-aws-cluster
CTX_CLUSTER2=kind-google-cluster

kubectl config use-context ${CTX_CLUSTER1}
helm install spire-aws spiffe/spire --namespace spire --create-namespace -f spire-values-aws.yaml
helm upgrade spire-aws spiffe/spire --namespace spire --create-namespace -f spire-values-aws.yaml

kubectl -n spire rollout status statefulset spire-aws-server
kubectl -n spire rollout status daemonset spire-aws-agent

kubectl -n spire apply -f nodePort-aws.yaml

aws_bundle=$(kubectl exec --stdin spire-aws-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe)

kubectl config use-context ${CTX_CLUSTER2}

helm install spire-google spiffe/spire --namespace spire --create-namespace -f spire-values-google.yaml
helm upgrade spire-google spiffe/spire --namespace spire --create-namespace -f spire-values-google.yaml

kubectl -n spire rollout status statefulset spire-google-server
kubectl -n spire rollout status daemonset spire-google-agent

kubectl -n spire apply -f nodePort-google.yaml

aws_b="$aws_bundle" \
yq eval -n '{
    "apiVersion": "spire.spiffe.io/v1alpha1",
    "kind": "ClusterFederatedTrustDomain",
    "metadata": {
        "name": "aws"
    },
    "spec": {
        "trustDomain": "aws.com",
        "bundleEndpointURL": "https://aws-cluster-worker:30007",
        "bundleEndpointProfile": {
            "type": "https_spiffe",
            "endpointSPIFFEID": "spiffe://aws.com/spire/server"
        },
        "trustDomainBundle": strenv(aws_b)
    }
}' > federation-google.yaml


kubectl -n spire apply -f federation-google.yaml

google_bundle=$(kubectl exec --stdin spire-google-server-0 -c spire-server -n spire  --  /opt/spire/bin/spire-server bundle show -format spiffe)

kubectl config use-context ${CTX_CLUSTER1}

google_b="$google_bundle" \
yq eval -n '{
    "apiVersion": "spire.spiffe.io/v1alpha1",
    "kind": "ClusterFederatedTrustDomain",
    "metadata": {
        "name": "google"
    },
    "spec": {
        "trustDomain": "google.com",
        "bundleEndpointURL": "https://google-cluster-worker:30007",
        "bundleEndpointProfile": {
            "type": "https_spiffe",
            "endpointSPIFFEID": "spiffe://google.com/spire/server"
        },
        "trustDomainBundle": strenv(google_b)
    }
}' > federation-aws.yaml

kubectl -n spire apply -f federation-aws.yaml


