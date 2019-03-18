#/bin/bash

REMOTE_PEER_NAME=rpeer1-ibmcloud

helm delete --purge ${REMOTE_PEER_NAME}

kubectl delete secret --all