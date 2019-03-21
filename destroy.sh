#/bin/bash

source values.sh

helm delete --purge ${REMOTE_PEER_NAME}

kubectl delete secret -l app=hlf-${REMOTE_PEER_NAME}