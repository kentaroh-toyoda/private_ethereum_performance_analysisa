#!/bin/bash
export BOOTNODE_IP=
export NETWORK_ID=138634
container='sender-1'

echo -e "\e[1;42m > [$(hostname)] Starting up sender \e[0m"
cd ~/poa_analysis/sender/tools
docker-compose down
docker-compose build --build-arg FROM=${from} --build-arg PASSWORD=${password} ${container}
docker-compose up --no-color &> sender_output_$(hostname).log &
sleep 30

datetime="$(date +'%Y-%m-%d-%T')"
echo -e "\e[1;42m > [$(hostname) | ${datetime}] Sending tx \e[0m"
docker exec -t ${container} echo "> [$(hostname)] Total #tx: $nTxs"
# docker exec -t ${container} node ./check_balance.js
docker exec -t ${container} node ./send_ether.js -n ${nTxs} -s ${from} -r ${to} -p ${password} > tx_sent_report_$(hostname).log
sleep 5

echo -e "\e[1;42m > [$(hostname)] Tx sent \e[0m"
echo -e "\e[1;42m > [$(hostname)] Halting docker-compose... \e[0m"
docker-compose down
