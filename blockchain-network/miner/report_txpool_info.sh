#/bin/bash
echo '{"jsonrpc":"2.0","method":"txpool_inspect","params":[],"id":1}' | nc -U /root/.ethereum/geth.ipc
