#/bin/bash

istioctl install -f istio-conf-new-aws.yaml --skip-confirmation
kubectl apply -f auth.yaml
kubectl apply -f istio-ew-gw.yaml
