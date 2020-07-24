#!/bin/bash
# set working dir
cd "${0%/*}"

nIter=$1
nTxs=5000
nMiners=3
senderHosts=( 'idra' 'rhodes' )
# senderHosts=( 'idra' )
basePprofPort=6060
# The followings are just for naming, not used in other codes
memory='8g'
# memories=( '1g' '2g' '4g' '8g' )
nCPU=8
# nCPUs=( 1 2 4 8 )
blockInterval=1
# blockIntervals=( 1 2 4 8 )
isCgo='true'
isSC='false'
nTxCacher=8 
# smartContract='FungibleTokenBurn' # DoNothing, CPUHeavy, KVStore, FungibleTokenMint, FungibleTokenBurn
# smartContracts=( 'DoNothing' 'FungibleTokenMint' 'FungibleTokenBurn' 'KVStore' 'CPUHeavy' )
isLogOff='true'

if [ "${isSC}" = "true" ]
then 
  senderDir='sender-sc'
  sleepAfterDeploy=40
  # subDir='tools'
else
  senderDir='sender'
  sleepAfterDeploy=30
  # subDir='tools'
fi

# for blockInterval in "${blockIntervals[@]}"
# for smartContract in "${smartContracts[@]}"
# for nCPU in "${nCPUs[@]}"
# for memory in "${memories[@]}"
# do
echo -e "\e[1;46m > Update .env and genesis.json... \e[0m"
# .env
sed -i "s/N_CPU=.*/N_CPU=${nCPU}/g" .env
sed -i "s/MEMORY=.*/MEMORY=${memory}/g" .env
# genesis.json
sed -i -E "s/\"period\": [0-9]+/\"period\": ${blockInterval}/g" genesis.json

echo -e "\e[1;46m > Copying necessary files... \e[0m"
cp ./genesis.json ./miner/
cp ./genesis.json ./node/
cp ./genesis.json ../${senderDir}/tools/

for host in "${senderHosts[@]}"
do
  echo -e "\e[1;42m _ to ${host} \e[0m"
  ssh ${host} "rm -rf ~/poa_analysis/${senderDir}"
  scp -r ../${senderDir} "${host}:~/poa_analysis/"
done

for i in $(seq 1 ${nIter})
do
  sleep 5
  # try stopping dockers for in case
  docker-compose down

    # make a directory for store logs
    datetime="$(date +'%Y-%m-%d-%T')"
    if [ "${isSC}" = "true" ]
    then
      logdir="./log/${datetime}_memory_${memory}_nCPU_${nCPU}_nMiners_${nMiners}_nTxs_$(expr ${nTxs} \* ${#senderHosts[@]})_blockInterval_${blockInterval}_cgo_${isCgo}_nTxCacher_${nTxCacher}_isSC_${isSC}_SC_${smartContract}_isLogOff_${isLogOff}"
    else
      logdir="./log/${datetime}_memory_${memory}_nCPU_${nCPU}_nMiners_${nMiners}_nTxs_$(expr ${nTxs} \* ${#senderHosts[@]})_blockInterval_${blockInterval}_cgo_${isCgo}_nTxCacher_${nTxCacher}_isSC_${isSC}_isLogOff_${isLogOff}"
    fi
    mkdir -p ${logdir}

    echo -e "\e[1;46m > Building docker containers \e[0m"
    docker-compose build

    echo -e "\e[1;46m > Starting up a bootnode and miners... \e[0m"
    docker-compose up --no-color &> ${logdir}/miners_output.log &

    echo -e "\e[1;46m > Executing remote ${senderDir}... \e[0m"
    for i in $(seq 1 ${#senderHosts[@]})
    do
      echo -e "\e[1;42m _ ${senderHosts[$(expr $i - 1)]} \e[0m"
      from=$i
      to=$(expr $i + 1)
      password=${to}
      if [ "${isSC}" = "true" ]
      then
        ssh ${senderHosts[$(expr $i - 1)]} nTxs=${nTxs} from=${from} password=${password} to=${to} smartContract=${smartContract} 'bash -s' < ./remote_docker_control_sc.sh &
      else
        ssh ${senderHosts[$(expr $i - 1)]} nTxs=${nTxs} from=${from} to=${to} password=${password} 'bash -s' < ./remote_docker_control.sh &
      fi
    done
    sleep ${sleepAfterDeploy} # This waits for remote senders

    echo -e "\e[1;46m > Starting docker stats and pprof... \e[0m"
    mkdir -p ${logdir}/pprof
    for i in $(seq 1 10)
    do
      # output docker stats into a file
      docker stats -a --no-stream > ${logdir}/$(date +'%Y-%m-%d-%T')_docker_stats.log
      for iMiner in $(seq 1 ${nMiners})
      do
        # set port number for pprof
        portPprof=$(expr ${basePprofPort} + ${iMiner} - 1)
        urlPrefix="http://localhost:${portPprof}/debug/pprof"

        # cpuprofile can be measured every 30 second
        if [ $i -eq 1 ]
        then
          docker exec -t miner-${iMiner} go tool pprof -text ${urlPrefix}/profile > ${logdir}/pprof/miner-${iMiner}_profile_${i}.out &
        fi
        docker exec -t miner-${iMiner} go tool pprof -text ${urlPrefix}/goroutine > ${logdir}/pprof/$(date +'%Y-%m-%d-%T')_miner-${iMiner}_goroutine_${i}.out &
        docker exec -t miner-${iMiner} go tool pprof -text ${urlPrefix}/block > ${logdir}/pprof/$(date +'%Y-%m-%d-%T')_miner-${iMiner}_block_${i}.out &
        # docker exec -t miner-${iMiner} go tool pprof -text ${urlPrefix}/heap > ${logdir}/pprof/$(date +'%Y-%m-%d-%T')_miner-${iMiner}_heap_${i}.out &
        # docker exec -t miner-${iMiner} go tool pprof ${urlPrefix}/mutex &
        # docker exec -t miner-${iMiner} go tool pprof ${urlPrefix}/threadcreate &
      done
      sleep 3
    done
    # sleep 10

    echo -e "\e[1;46m > Getting block info from a miner... \e[0m"
    # Get the block height
    blockHeight="$(docker exec -it miner-1 geth --ipcpath /root/.ethereum/geth.ipc --exec eth.blockNumber attach | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK](\\r)?//g")"

    echo "Block height: $blockHeight"

    mkdir -p ${logdir}/blocks

    # Get block info one-by-one
    for block in $(seq 1 $blockHeight)
    do
      filename="${logdir}/blocks/${block}.json"
      # get block
      docker exec -it miner-1 geth --ipcpath /root/.ethereum/geth.ipc --exec "eth.getBlock($block)" attach > $filename
      # decolor
      sed -ri "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" $filename
      # convert JavaScript objects to JSON
      sed -ri 's/(\w+)/"\1"/' $filename
    done
    echo -e "\e[1;46m > Getting logs from remote senders... \e[0m"
    for i in "${senderHosts[@]}"
    do
      echo -e "\e[1;42m _ ${i} \e[0m"
      scp "${i}:~/poa_analysis/${senderDir}/tools/tx_sent_report_${i}.log" ${logdir}
      scp "${i}:~/poa_analysis/${senderDir}/tools/sender_output_${i}.log" ${logdir}
    done

    echo -e "\e[1;46m > Getting pprof from miners... \e[0m"
    for i in $(seq 1 $nMiners)
    do
      mkdir ${logdir}/pprof/miner-${i}
      docker cp miner-${i}:/root/pprof/. ${logdir}/pprof/miner-${i}
    done

    # echo -e "\e[1;46m > Generating pprof trace PDFs... \e[0m"
    # for i in $(seq 1 ${nMiners})
    # do
      # pprofLogs=( ${logdir}/pprof/miner-${i}/pprof.geth.samples.cpu.001.pb.gz ${logdir}/pprof/miner-${i}/pprof.geth.contentions.delay.005.pb.gz )

      # for file in ${pprofLogs[@]}
      # do
      # SVG="${file}.svg"
      # PDF="${file}.pdf"
      # # covert to svg
      # go tool pprof -svg -output $SVG $file
      # # convert to pdf
      # inkscape --file=${SVG} --export-area-drawing --without-gui --export-pdf=${PDF}
      # done
      # done
    # done
    echo -e "\e[1;46m > Halting docker-compose... \e[0m"
    docker-compose down
done
# done
