# Overview
Docker configuration toolset for PoA private Ethereum network.

* Geth v1.9.10-stable (modified to output elapsed time for each function in `clique.go`)
* 1 bootnode, $N_\mathrm{seal}$ sealers (miners) and $N_\mathrm{send}$ senders
* 192.0.0.0/24 private network is built.
* Several log fies by `pprof` and `docker stats` are used for analysis.

## Create an Account in the test Ethereum

`./bin/geth account new`

## Create a Network with Automated Puppeth

An Ethereum network can be created by `create_genesis_automatically.sh`.

## Usage

* `git clone https://github.com/ethereum/go-ethereum.git`
* `cd go-ethereum && make all`
* Copy `geth` and `bootnode` in `go-ethereum/build/bin/` to `blockchain-network/bootnode/`, `blockchain-network/miner/`, `sender/tools/` and `sender-sc/tools/`
* Specify the IP address of server that runs `bootnode` in `blockchain-network/repeat_measurement.sh`, `blockchain-network/repeat_measurement.sh`, Dockerfiles and `.env` in `sender` and `sender-sc`
* `cd blockchain-network`
* `./repeat_measurement.sh 10`

## Licence

MIT Licence

## Author

[Kentaroh TOYODA](kentaroh.toyoda@ieee.org)
