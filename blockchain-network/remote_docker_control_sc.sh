#!/bin/bash
export BOOTNODE_IP=
export NETWORK_ID=138634
container='sender-sc-1'

echo -e "\e[1;42m > [$(hostname)] Starting up sender-sc... \e[0m"
cd ~/poa_analysis/sender-sc/tools
docker-compose down
docker-compose build --build-arg FROM=${from} --build-arg PASSWORD=${password} sender-sc
docker-compose up --no-color &> sender_output_$(hostname).log &
sleep 30

echo -e "\e[1;42m > [$(hostname)] Deploying smart contracts... \e[0m"
# docker container ls
docker exec -t ${container} node ./${smartContract}/deploy.js -s $from -p $password
sleep 10
echo -e "\e[1;42m > [$(hostname)] Testing smart contracts... \e[0m"
docker exec -t ${container} node ./${smartContract}/test.js -s $from -r $to -p $password -n $nTxs > tx_sent_report_$(hostname).log
sleep 5

echo -e "\e[1;42m > [$(hostname)] Tx sent \e[0m"
echo -e "\e[1;42m > [$(hostname)] Halting docker-compose... \e[0m"
docker-compose down
