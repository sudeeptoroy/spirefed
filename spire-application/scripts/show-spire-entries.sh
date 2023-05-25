#!/bin/bash

set -eo pipefail

kubectl exec -t \
    -nspire \
    -c spire-server deployment/spire-server -- \
        /opt/spire/bin/spire-server entry show
