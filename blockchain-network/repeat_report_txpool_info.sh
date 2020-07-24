#!/bin/bash

for i in $(seq 1 120)
do
	# docker exec -t miner-1 ./report_txpool_info.sh > log/txpool/${i}.json
	filename="./log/txpool/${i}.json"

	docker exec -t miner-1 geth --ipcpath /root/.ethereum/geth.ipc --exec "txpool.inspect" attach  > $filename
	# decolor
	sed -ri "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" $filename
	# convert JavaScript objects to JSON
	sed -ri 's/(\w+)/"\1"/' $filename
	sleep 0.5
done
