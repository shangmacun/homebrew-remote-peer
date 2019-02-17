#/bin/bash

set -e
export PATH=${PWD}/bin:$PATH

REMOTE_PEER_NAME=rpeer1
CA_USERNAME=${REMOTE_PEER_NAME}
CA_PASSWORD=${REMOTE_PEER_NAME}pw
ORGADMIN_NAME=Org1OrgAdmin
CA_HOSTNAME=184.172.241.177
CA_PORT=30218
CA_TLS_CRT=$(ls data/ca-tls-root-cert/*.pem)

export FABRIC_CA_CLIENT_HOME=${PWD}

rm -rf ${PWD}/data/${REMOTE_PEER_NAME}/msp
rm -rf ${PWD}/data/${REMOTE_PEER_NAME}/tls

mkdir -p ${PWD}/data/${REMOTE_PEER_NAME}/tls
mkdir -p ${PWD}/data/${REMOTE_PEER_NAME}/msp/tlscacerts

fabric-ca-client getcainfo -d -u https://${CA_HOSTNAME}:${CA_PORT} -M ./tmp --tls.certfiles ${CA_TLS_CRT} 

cp ./tmp/cacerts/* ${PWD}/data/${REMOTE_PEER_NAME}/msp/tlscacerts
rm -rf ./tmp

fabric-ca-client enroll -u https://${CA_USERNAME}:${CA_PASSWORD}@${CA_HOSTNAME}:${CA_PORT} -M ./tmp --tls.certfiles ${CA_TLS_CRT}

cp -r ./tmp/ ${PWD}/data/${REMOTE_PEER_NAME}/msp/
rm ${PWD}/data/${REMOTE_PEER_NAME}/msp/IssuerPublicKey
rm ${PWD}/data/${REMOTE_PEER_NAME}/msp/IssuerRevocationPublicKey
rm -rf ./tmp

fabric-ca-client enroll -d --enrollment.profile tls -u https://${CA_USERNAME}:${CA_PASSWORD}@${CA_HOSTNAME}:${CA_PORT} --tls.certfiles $CA_TLS_CRT --csr.hosts ${REMOTE_PEER_NAME},${REMOTE_PEER_NAME}-hlf-peer -M ./tmp

mv ./tmp/signcerts/cert.pem data/${REMOTE_PEER_NAME}/tls/server.pem
mv ./tmp/keystore/* data/${REMOTE_PEER_NAME}/tls/server.key
cp data/${REMOTE_PEER_NAME}/msp/tlscacerts/*.pem data/${REMOTE_PEER_NAME}/tls/ca.pem
rm -rf ./tmp

echo "Checking ${ORGADMIN_NAME} MSP.."
if [ ! -d data/users/${ORGADMIN_NAME}/msp ]; then
    echo "${ORGAGMIN} MSP directory not found"
    exit 1
else
    echo "OK"
fi

echo "Checking Orderer CA TLS Root Cert.."
if [ ! -d data/orderer-ca-tls-root-cert ]; then
    echo "Orderer CA TLS Root Cert directory not found"
    exit 1
else
    echo "OK"
fi