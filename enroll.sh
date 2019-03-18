#/bin/bash

set -e
export PATH=${PWD}/bin:$PATH

REMOTE_PEER_NAME=rpeer2-aws
CA_USERNAME=${REMOTE_PEER_NAME}
CA_PASSWORD=${REMOTE_PEER_NAME}pw
TLSCA_USERNAME=${REMOTE_PEER_NAME}tls
TLSCA_PASSWORD=${TLSCA_USERNAME}pw
ORGADMIN_NAME=Org1OrgAdmin
CA_HOSTNAME=184.172.241.177
CA_PORT=30606
CA_TLS_CRT=$(ls $PWD/data/ca-tls-cert/*.pem)

export FABRIC_CA_CLIENT_HOME=${PWD}

rm -rf ${PWD}/data/${REMOTE_PEER_NAME}/msp
rm -rf ${PWD}/data/${REMOTE_PEER_NAME}/tls
rm -rf ./tmpca
rm -rf ./tmptlsca

mkdir -p ${PWD}/data/${REMOTE_PEER_NAME}/tls

fabric-ca-client enroll --caname ca -u https://${CA_USERNAME}:${CA_PASSWORD}@${CA_HOSTNAME}:${CA_PORT} -M ./tmpca --tls.certfiles ${CA_TLS_CRT}

cp -r ./tmpca/ ${PWD}/data/${REMOTE_PEER_NAME}/msp/
mkdir -p ${PWD}/data/${REMOTE_PEER_NAME}/msp/tlscacerts
cp ${PWD}/data/${REMOTE_PEER_NAME}/msp/cacerts/*.pem ${PWD}/data/${REMOTE_PEER_NAME}/msp/tlscacerts

rm ${PWD}/data/${REMOTE_PEER_NAME}/msp/IssuerPublicKey
rm ${PWD}/data/${REMOTE_PEER_NAME}/msp/IssuerRevocationPublicKey
rm -rf ./tmpca

fabric-ca-client enroll --caname tlsca -u https://${TLSCA_USERNAME}:${TLSCA_PASSWORD}@${CA_HOSTNAME}:${CA_PORT} --tls.certfiles $CA_TLS_CRT --csr.hosts ${REMOTE_PEER_NAME},${REMOTE_PEER_NAME}-hlf-peer,${REMOTE_PEER_NAME}.aldred.space -M ./tmptlsca

mv ./tmptlsca/signcerts/cert.pem data/${REMOTE_PEER_NAME}/tls/server.pem
mv ./tmptlsca/keystore/* data/${REMOTE_PEER_NAME}/tls/server.key
mv ./tmptlsca/cacerts/*.pem data/${REMOTE_PEER_NAME}/tls/ca.pem
rm -rf ./tmptlsca

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