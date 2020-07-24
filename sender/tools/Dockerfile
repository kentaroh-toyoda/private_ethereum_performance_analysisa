FROM ubuntu:bionic

# instal reqiured packages. node is used for send ether
RUN apt update
RUN apt install -y git make g++ curl
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN apt install -y nodejs
RUN npm i web3@1.2.2 ethereumjs-tx@1.3.7 websocket@latest p-map@latest p-throttle@latest yargs@latest keythereum@1.0.4
RUN apt install -y parallel

# copy binaries
COPY ./geth /bin/
COPY ./bootnode /bin/

WORKDIR /root

ARG FROM
ARG PASSWORD

RUN echo $PASSWORD | tee ~/.password

# prepair required files for geth
COPY ./genesis.json .

RUN geth removedb
COPY ./keystore/* .ethereum/keystore/
COPY ./bootnode.key .
# For simple tx send test
COPY ./*.js ./

# configure a blockchain
RUN geth init genesis.json
# check if an account is loaded by a correct keystore
RUN geth account list

# execute geth 
CMD geth --bootnodes "enode://$(/bin/bootnode --nodekey=bootnode.key --writeaddress)@$BOOTNODE_IP:30301" --networkid "$NETWORK_ID" --nousb --verbosity 3 --syncmode fast --unlock "$FROM" --password "~/.password" --allow-insecure-unlock --ws --wsapi admin,eth,db,personal,net,web3

EXPOSE 8546
# EXPOSE 30303
