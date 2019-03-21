#/bin/bash

source values.sh

echo "Creating k8s secrets.."

kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cred --from-literal=CA_USERNAME=${CA_USERNAME} --from-literal=CA_PASSWORD=${CA_PASSWORD}

CERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idcert --from-file=cert.pem=${CERT}

KEY=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/keystore/*)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idkey --from-file=key=${KEY}

CACERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/cacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cacert --from-file=cacert.pem=${CACERT}

TLSCACERT=$(ls ${PWD}/data/peers/${REMOTE_PEER_NAME}/msp/tlscacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tlscacert --from-file=tlscacert.pem=${TLSCACERT}

ADMINCERT=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--${ORGMSP_ID}-admincert --from-file=${ADMINCERT}

ADMINKEY=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/keystore/*)
kubectl create secret generic hlf--${ORGMSP_ID}-adminkey --from-file=${ADMINKEY}

ORDERER_CA_TLS_ROOT_CERT=$(ls ${PWD}/data/orderer-ca-tls-root-cert/*.pem)
kubectl create secret generic hlf--${ORGMSP_ID}-ord-tlsrootcert --from-file=${ORDERER_CA_TLS_ROOT_CERT}

TLS_CRT=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/server.pem
TLS_KEY=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/server.key
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tls --from-file=tls.crt=${TLS_CRT} --from-file=tls.key=${TLS_KEY}

TLS_ROOT_CRT=${PWD}/data/peers/${REMOTE_PEER_NAME}/tls/ca.pem
kubectl create secret generic hlf--${ORGMSP_ID}-tlsrootcert --from-file=cacert.pem=${TLS_ROOT_CRT}

echo "Generating values file.."
sed -e "s/%REMOTE_PEER_NAME%/${REMOTE_PEER_NAME}/g" -e "s/%BOOTSTRAP_PEER%/${BOOTSTRAP_PEER}/g" -e "s/%ORGMSP_ID%/${ORGMSP_ID}/g" values.yaml.base > values.yaml

helm install ./hlf-peer -n ${REMOTE_PEER_NAME} -f values.yaml