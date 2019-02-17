# Homebrew HF Remote Peer

This will deploy a remote peer in your K8S cluster, connecting to the main blockchain network.

## Defaults

* Remote Peer Name: **rpeer1** - You can change by browsing through the scripts and change REMOTE_PEER_NAME parameter
* Hyperledger Fabric Version: `1.4.0` - In conformance to the HF version of IBM Blockchain Platform v2.0
* Default Service Type: `NodePort` - So that it can be deployed into free clusters or Minikube
* MSP Name: org1msp
* Peer Org Admin Name: **Org1OrgAdmin** - You can change by browsing through the scripts and change ORGADMIN_NAME parameter
* Channel Name: channel1

The above default settings can be changed by altering [remote-peer-values.yaml](remote-peer-values.yaml) file

## Prerequisities

### Main Blockchain network

You should have done the following:

* Registered the remote peer to the Peer Org's CA (enrollment will be done via provided scripts)
* Created a channel, joined a peer to that channel, installed and instantiated a chaincode - [Sample Chaincode](chaincode/chaincode1@1.cds). IBPv2 accepts .cds chaincode files through its GUI.

### Kubernetes and Helm

You should have a K8S cluster (obviously). Install Helm in your local machine and Tiller in the K8S

```bash
helm init
```

### Minikube Hairpin Mode

If you're running on Minikube, turn on hairpin mode so that the peer can call itself when performing various operations (join channel, etc)

```bash
minikube ssh
sudo ip link set docker0 promisc on
```

### fabric-ca-client

In [bin](bin/) folder, place **fabric-ca-client** binary file (v1.4.0) as the script will perform enrollment

### Parameters to be altered

In [remote-peer-values.yaml](remote-peer-values.yaml), change value of `peer.gossip.bootstrap` to a Peer address in the main blockchain network (should be same organization)

In [deploy.sh](deploy.sh), [enroll.sh](enroll.sh) and [destroy.sh](destroy.sh) change values of:

* `REMOTE_PEER_NAME` - Self explanatory
* `CA_USERNAME` - The username of the remote peer registered in Peer Org's CA
* `CA_PASSWORD` - The password of the remote peer registered in Peer Org's CA
* `ORGADMIN_NAME` - The name of the org admin
* `CA_HOSTNAME` - Self explanatory
* `CA_PORT` - Self explanatory

### Certificates

You will require to place the following certificates (any filename is OK):

* Peer Org's CA TLS Root Cert in [data/ca-tls-root-cert](data/ca-tls-root-cert)
* Orderer's CA TLS Root Cert in [data/ca-tls-root-cert](data/ca-tls-root-cert)
* Peer Org Admin's Cert and Key in [data/users/$ORGADMIN_NAME/msp/signcerts](data/users/Org1OrgAdmin/msp/signcerts) and [data/users/$ORGADMIN_NAME/msp/keystore](data/users/Org1OrgAdmin/msp/keystore) respectively

## Deployment

### Enrolling Remote Peer

Provided that you met the prerequisites above, run:

```bash
./enroll.sh
```

### Deploy

This will create secrets based on the certificates provided and deploy a helm chart

```bash
./deploy.sh
```

Once deployment is done, get the pod's name:

```bash
REMOTE_PEER_NAME=rpeer1
POD=$(kubectl get pods -l "app=hlf-peer,release=${REMOTE_PEER_NAME}" -o jsonpath="{.items[0].metadata.name}")
```

### Destroy

This will remove the release and destroys all secrets in the `default` namespace

```bash
./destroy.sh
```

## Join Channel

```bash
docker exec -it $POD bash
```

Retrieve Channel Genesis Block

```bash
ORDERER=184.172.241.177:30971 #Should change to your orderer address
CHANNEL=channel1
peer channel fetch 0 /var/hyperledger/channel_genesis.pb -c $CHANNEL -o $ORDERER --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem
```

Join Channel

```bash
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer channel join -b /var/hyperledger/channel_genesis.pb
```

## Chaincode Operations

Install and Query Chaincode

```bash
CHANNEL=channel1
CHAINCODE=chaincode1
kubectl cp ./chaincode/chaincode1@1.cds ${POD}:/var/hyperledger/
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode install /var/hyperledger/chaincode1\@1.cds
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode query -C $CHANNEL -n $CHAINCODE -c '{"Args":["query","a"]}'
```

Invoke Chaincode

```bash
ORDERER=184.172.241.177:30971 #Should change to your orderer address
CHANNEL=channel1
CHAINCODE=chaincode1
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode invoke -o $ORDERER --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem -C $CHANNE -n $CHAINCODE -c '{"Args":["put","a","10"]}'
```

## Other useful command dumps

```bash
configtxlator proto_decode --input channel1.block --type common.Block
```