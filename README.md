# Homebrew HF Remote Peer

This will deploy a remote peer in your K8S cluster, connecting to the main blockchain network.

## Prerequisities

### HF binaries

Download binaries for Hyperledger Fabric v1.4.1

```bash
curl -sSL http://bit.ly/2ysbOFE | bash -s -- 1.4.1 -d -s
rm -f config/configtx.yaml config/core.yaml config/orderer.yaml
```

### Kubernetes and Helm

You should have a K8S cluster (obviously). Install Helm in your local machine and Tiller in the K8S

```bash
helm init
helm version
```

If you see `Error: could not find a ready tiller pod`, wait for a while and try again

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

In [bin](bin/) folder, check if you have `fabric-ca-client`

### Parameters to be altered

In `values.sh`, change/alter the following as necessary. You might want to download **Connection Profile** to assist in filling up some of the parameters

* `REMOTE_PEER_NAME` - Same as the peer's enrollment ID
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
* `CHANNEL` - Channel Name

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

Make sure that peer is running:

```bash
kubectl get pod
```

Once deployment is done, get the pod's name:

```bash
source values.sh
POD=$(kubectl get pods -l "app=hlf-peer,release=${REMOTE_PEER_NAME}" -o jsonpath="{.items[0].metadata.name}")
```

## Join Channel

```bash
kubectl exec -it $POD -c peer bash
```

Retrieve Channel Genesis Block

```bash
peer channel fetch 0 /var/hyperledger/channel_genesis.pb -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem
```

Join Channel

```bash
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer channel join -b /var/hyperledger/channel_genesis.pb
```

Exit

```bash
exit
```

## Chaincode Operations

Install and Query Chaincode

```bash
kubectl cp ./chaincode/sample@1.cds ${POD}:/var/hyperledger/ -c peer
kubectl exec -it $POD -c peer bash
```

```bash
CHAINCODE=sample
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode install /var/hyperledger/sample\@1.cds
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE -c '{"Args":["query","a"]}'
```

Invoke Chaincode

```bash
CHAINCODE=sample
CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile /var/hyperledger/tls/ord/cert/orderer-ca-tls-root-cert.pem -C $CHANNEL_NAME -n $CHAINCODE -c '{"Args":["put","a","10"]}'

CORE_PEER_ADDRESS=$CORE_PEER_GOSSIP_BOOTSTRAP CORE_PEER_MSPCONFIGPATH=$ADMIN_MSP_PATH peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile $ORD_TLS_PATH/orderer-ca-tls-root-cert.pem -C $CHANNEL_NAME -n $CHAINCODE -c '{"Args":["put","a","13"]}'
```

## Destroy

This will remove the release and destroys all secrets in the `default` namespace

```bash
./destroy.sh
```
