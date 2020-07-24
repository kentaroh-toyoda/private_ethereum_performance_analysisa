FROM ubuntu:bionic

ARG MINER_ID
# ARG PPROF_PORT

RUN apt update
RUN apt install -y software-properties-common
RUN add-apt-repository -y ppa:longsleep/golang-backports
RUN apt update
RUN apt install -y curl golang-go

# copy binaries
COPY ./geth /bin/
COPY ./bootnode /bin/

WORKDIR /root

# prepair required files for geth
COPY ./genesis.json .
# COPY ./report_txpool_info.sh .

RUN geth removedb
COPY ./keystore/$MINER_ID/* .ethereum/keystore/
COPY ./bootnode.key .
RUN echo $MINER_ID > .password # INFO: a password is same as $MINER_ID

# configure a blockchain
RUN geth init genesis.json
# check if an account is loaded by a correct keystore
RUN geth account list

# start miner process
CMD geth --bootnodes "enode://$(/bin/bootnode --nodekey=bootnode.key --writeaddress)@$BOOTNODE_IP:30301" --networkid "$NETWORK_ID" --verbosity 5 --txpool.accountqueue 65536 --txpool.globalqueue 65536 --txpool.accountqueue 65536 --txpool.globalqueue 65536 --syncmode full --mine --miner.gasprice 0 --miner.gastarget 4294967296 --miner.gaslimit 4294967296 --miner.threads $N_CPU --miner.etherbase "0" --unlock "0" --password ".password" --txpool.globalslots 65536 --txpool.accountslots 65536 --txpool.accountqueue 65536 --txpool.globalqueue 65536 --nousb --cache $MEMCACHE_MB --metrics --pprof --pprofport $PPROF_PORT --memprofilerate 524288 --blockprofilerate 1 --trace geth_trace_$(hostname).log

EXPOSE 30303
EXPOSE $PPROF_PORT
