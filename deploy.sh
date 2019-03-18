#/bin/bash

REMOTE_PEER_NAME=rpeer2-aws
CA_USERNAME=${REMOTE_PEER_NAME}
CA_PASSWORD=${REMOTE_PEER_NAME}pw
ORGADMIN_NAME=Org1OrgAdmin

echo "Creating k8s secrets.."

kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cred --from-literal=CA_USERNAME=${CA_USERNAME} --from-literal=CA_PASSWORD=${CA_PASSWORD}

CERT=$(ls ${PWD}/data/${REMOTE_PEER_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idcert --from-file=cert.pem=${CERT}

KEY=$(ls ${PWD}/data/${REMOTE_PEER_NAME}/msp/keystore/*)
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-idkey --from-file=key=${KEY}

CACERT=$(ls ${PWD}/data/${REMOTE_PEER_NAME}/msp/cacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-cacert --from-file=cacert.pem=${CACERT}

TLSCACERT=$(ls ${PWD}/data/${REMOTE_PEER_NAME}/msp/tlscacerts/*.pem )
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tlscacert --from-file=tlscacert.pem=${TLSCACERT}

ADMINCERT=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/signcerts/*.pem)
kubectl create secret generic hlf--peer-admincert --from-file=${ADMINCERT}

ADMINKEY=$(ls ${PWD}/data/users/${ORGADMIN_NAME}/msp/keystore/*)
kubectl create secret generic hlf--peer-adminkey --from-file=${ADMINKEY}

ORDERER_CA_TLS_ROOT_CERT=$(ls ${PWD}/data/orderer-ca-tls-root-cert/*.pem)
kubectl create secret generic hlf--ord-tlsrootcert --from-file=${ORDERER_CA_TLS_ROOT_CERT}

TLS_CRT=${PWD}/data/${REMOTE_PEER_NAME}/tls/server.pem
TLS_KEY=${PWD}/data/${REMOTE_PEER_NAME}/tls/server.key
kubectl create secret generic hlf--${REMOTE_PEER_NAME}-tls --from-file=tls.crt=${TLS_CRT} --from-file=tls.key=${TLS_KEY}

TLS_ROOT_CRT=${PWD}/data/${REMOTE_PEER_NAME}/tls/ca.pem
kubectl create secret generic hlf--peer-tlsrootcert --from-file=cacert.pem=${TLS_ROOT_CRT}

helm install ./hlf-peer -n ${REMOTE_PEER_NAME} -f remote-peer-values.yaml