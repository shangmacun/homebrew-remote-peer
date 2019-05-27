#/bin/bash

set -e
source values.sh

echo "Creating k8s secrets.."

kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cred --from-literal=CA_USERNAME=${CA_USERNAME} --from-literal=CA_PASSWORD=${CA_PASSWORD}
kubectl label secret hlf--${REMOTE_PEER_NAME}-cred app=hlf-${REMOTE_PEER_NAME}

CERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idcert --from-file=cert.pem=${CERT}
kubectl label secret hlf--${REMOTE_PEER_NAME}-idcert app=hlf-${REMOTE_PEER_NAME}

KEY=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/keystore/*)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idkey --from-file=key=${KEY}
kubectl label secret hlf--${REMOTE_PEER_NAME}-idkey app=hlf-${REMOTE_PEER_NAME}

CACERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/cacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cacert --from-file=cacert.pem=${CACERT}
kubectl label secret hlf--${REMOTE_PEER_NAME}-cacert app=hlf-${REMOTE_PEER_NAME}

TLSCACERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/tlscacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tlscacert --from-file=tlscacert.pem=${TLSCACERT}
kubectl label secret hlf--${REMOTE_PEER_NAME}-tlscacert app=hlf-${REMOTE_PEER_NAME}

ADMINCERT=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--${ORGMSP_ID}-admincert --from-file=${ADMINCERT}
kubectl label secret hlf--${ORGMSP_ID}-admincert app=hlf-${REMOTE_PEER_NAME}

ADMINKEY=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/keystore/*)
kubectl create secret generic hlf--${ORGMSP_ID}-adminkey --from-file=${ADMINKEY}
kubectl label secret hlf--${ORGMSP_ID}-adminkey app=hlf-${REMOTE_PEER_NAME}

ORDERER_CA_TLS_ROOT_CERT=$(ls ${PWD}/data/orderer-ca-tls-root-cert/*.pem)
kubectl create secret generic hlf--${ORGMSP_ID}-ord-tlsrootcert --from-file=${ORDERER_CA_TLS_ROOT_CERT}
kubectl label secret hlf--${ORGMSP_ID}-ord-tlsrootcert app=hlf-${REMOTE_PEER_NAME}

TLS_CRT=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/server.pem
TLS_KEY=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/server.key
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tls --from-file=tls.crt=${TLS_CRT} --from-file=tls.key=${TLS_KEY}
kubectl label secret hlf--${REMOTE_PEER_NAME}-tls app=hlf-${REMOTE_PEER_NAME}

TLS_ROOT_CRT=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/ca.pem
kubectl create secret generic hlf--${ORGMSP_ID}-tlsrootcert --from-file=cacert.pem=${TLS_ROOT_CRT}
kubectl label secret hlf--${ORGMSP_ID}-tlsrootcert app=hlf-${REMOTE_PEER_NAME}

echo "Generating values file.."
sed -e "s/%REMOTE_PEER_NAME%/${REMOTE_PEER_NAME}/g" -e "s/%BOOTSTRAP_PEER%/${BOOTSTRAP_PEER}/g" -e "s/%ORGMSP_ID%/${ORGMSP_ID}/g" -e "s/%ORDERER%/${ORDERER}/g" -e "s/%CHANNEL%/${CHANNEL}/g" values.yaml.base > values.yaml

helm install ./hlf-peer -n ${REMOTE_PEER_NAME} -f values.yaml