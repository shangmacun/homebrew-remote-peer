#/bin/bash

REMOTE_PEER_NAME=rpeer1

helm delete --purge ${REMOTE_PEER_NAME}

kubectl delete secret --all