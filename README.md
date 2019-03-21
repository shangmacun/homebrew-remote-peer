# Homebrew HF Remote Peer

This will deploy a remote peer in your K8S cluster, connecting to the main blockchain network.

## Prerequisities

### Kubernetes and Helm

You should have a K8S cluster (obviously). Install Helm in your local machine and Tiller in the K8S

```bash
helm init
```

### IBPv2 Fabric network

1. Register the remote peer to the Peer Org's CA (enrollment will be done via provided scripts)

2. Register the remote peer to the Peer Org's TLS CA (Note that IBPv2 runs a separate TLS CA)
  
3. Create a channel (**channel1**), join a peer to that channel, installed and instantiated a chaincode - [Sample Chaincode](chaincode/sample@1.cds). IBPv2 accepts .cds chaincode files through its GUI.

4. Download **CA TLS cert** by following these instructions:
   1. In IBPv2 console, go to **Certificate Authority settings**
   2. Copy the contents in **TLS Certificate** field
   3. Issue the commands

      ```bash
      export TLS=<paste the contents here>
      mkdir -p ./tmp
      echo $TLS > ./tmp/ca-tls
      base64 --decode ./tmp/ca-tls > ./data/ca-tls-cert/ca-tls.pem
      ```

5. Download **Orderer TLS root cert** by following these instructions:
   1. In IBPv2 console, go to **Orderer settings**
   2. Copy the contents in **TLS Certificate** field
   3. Issue the commands

      ```bash
      export TLS=<paste the contents here>
      echo $TLS > ./tmp/orderer-ca-tls-root-cert
      base64 --decode ./tmp/orderer-ca-tls-root-cert > ./data/orderer-ca-tls-root-cert/orderer-ca-tls-root-cert.pem
      ```

6. Download **Org Admin** identity by following these instructions:
   1. In IBPv2 console, go to **Wallet** and choose the Org Admin
   2. Copy the contents in **Certificate** field
   3. Issue the commands

      ```bash
      export CERT=<paste the contents here>
      echo $CERT > ./tmp/admincert
      base64 --decode ./tmp/admincert > ./data/users/OrgAdmin/msp/signcerts/cert.pem
      ```

   4. Copy the contents in **Private Key** field
   5. Issue the commands

      ```bash
      export KEY=<paste the contents here>
      echo $KEY > ./tmp/adminkey
      base64 --decode ./tmp/adminkey > ./data/users/OrgAdmin/msp/keystore/key
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

In `values.sh`, change/alter the following as necessary:

* `REMOTE_PEER_NAME` - Self explanatory
* `CA_USERNAME` - The username of the remote peer registered in the Org's CA
* `CA_PASSWORD` - The password of the remote peer registered in the Org's CA
* `TLSCA_USERNAME` - The username of the remote peer registered in the Org's TLS CA
* `TLSCA_PASSWORD` - The password of the remote peer registered in the Org's TLS CA
* `ORGADMIN_NAME` - The name of the org admin (leave it as **OrgAdmin**)
* `ORGMSP_ID` - Org MSP ID
* `CA_HOSTNAME` - Self explanatory
* `CA_PORT` - Self explanatory
* `BOOTSTRAP_PEER` - Peer to connect to receive gossip messages
* `ORDERER` - Orderer Address

## Deployment

### Enrolling Remote Peer

Provided that you met all the prerequisites above, run:

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
source values.sh
POD=$(kubectl get pods -l "app=hlf-peer,release=${REMOTE_PEER_NAME}" -o jsonpath="{.items[0].metadata.name}")
```

### Destroy

This will remove the release and destroys all secrets in the `default` namespace

```bash
./destroy.sh
```

## Join Channel

```bash
kubectl exec -it $POD -c peer bash
```

Retrieve Channel Genesis Block

```bash
ORDERER=184.172.241.177:30755 #Should change to your orderer address
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
kubectl cp ./chaincode/sample@1.cds ${POD}:/var/hyperledger/ -c peer
kubectl exec -it $POD -c peer bash
```

```bash
CHANNEL=channel1
CHAINCODE=sample
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode install /var/hyperledger/sample\@1.cds
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode query -C $CHANNEL -n $CHAINCODE -c '{"Args":["query","a"]}'
```

Invoke Chaincode

```bash
ORDERER=184.172.241.177:30755 #Should change to your orderer address
CHANNEL=channel1
CHAINCODE=sample
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode invoke -o $ORDERER --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem -C $CHANNEL -n $CHAINCODE -c '{"Args":["put","a","10"]}'
```

## Other useful command dumps

```bash
configtxlator proto_decode --input channel1.block --type common.Block

PEER_ORG_TLS_ROOT_CRT=$(ls data/peer-org-ca-tls-root-cert/*.pem)
kubectl cp $PEER_ORG_TLS_ROOT_CRT $POD:/var/hyperledger

CORE_PEER_ADDRESS=184.172.241.177:30901 CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH CORE_PEER_TLS_ROOTCERT_FILE=/var/hyperledger/peer-org-tls-ca.pem peer chaincode invoke -o $ORDERER --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem -C $CHANNEL -n $CHAINCODE -c '{"Args":["put","a","13"]}'

```