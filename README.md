Follow the script 

## Note: 
1. follow the best practice for bringing up istio with kind. Follow this https://istio.io/latest/docs/setup/platform-setup/kind/ and https://istio.io/latest/docs/setup/platform-setup/docker/
1. best practice for LB on kind: https://kind.sigs.k8s.io/docs/user/loadbalancer/#setup-address-pool-used-by-loadbalancers


## To bringup
./bring-up.sh
## To verify
./verify.sh 
## To destroy
./kind/destroy.sh


## Note: With the latest I have added aliases and hence the setup will work. In case you want to repoduce the issue kindly remove the "trustDomainAliases" from the istio configs. files are: istio/istio-conf-new-aws.yaml and istio/istio-conf-new-google.yaml
