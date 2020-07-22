#!/bin/bash

export K3S_KUBECONFIG_MODE="644"
export K3S_URL="https://cp.nobodyknowswhereyouare.brmbmbmbmbm:6443"
export K3S_TOKEN=$(curl http://cp.nobodyknowswhereyouare.brmbmbmbmbm:6969 | jq '.token' | xargs)
curl -sfL https://get.k3s.io | sh -
