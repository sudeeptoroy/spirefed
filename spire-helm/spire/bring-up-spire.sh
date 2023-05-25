kubectl config use-context ${CTX_CLUSTER1}
helm install spire-aws charts/spire/ --namespace spire --create-namespace -f spire-values-aws.yaml

kubectl -n spire apply -f nodePort-aws.yaml

aws_bundle=$(kubectl exec --stdin spire-aws-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe)

kubectl config use-context ${CTX_CLUSTER2}

helm install spire-google charts/spire/ --namespace spire --create-namespace -f spire-values-google.yaml

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


