#! /bin/bash

if [ ! -d "./output" ]; then
    mkdir output
fi

SOCKET_SIZES="4M"
SEND_SIZES="128 1024 4096 32768 128K 4M"
SWITCH="on off"
PROTOS="TCP UDP"

for STATUS in $SWITCH
  do
  echo -e "Turn tx_tnl_segmentation $STATUS!"
  if [ ! -f "/var/run/netns/default" ]; then
    ln -s /proc/1/ns/net /var/run/netns/default
  fi
  ip netns exec default ethtool -K eth0 tx-udp_tnl-segmentation $STATUS
  ip netns exec default ethtool -k eth0 | grep tnl

  for PROTO in $PROTOS
  do
    for SOCKET_SIZE in $SOCKET_SIZES
      do
      for SEND_SIZE in $SEND_SIZES
        do
        echo
        echo ------------------------------------
        echo
        echo "Run netperf with $PROTO message size $SEND_SIZE, socket size $SOCKET_SIZE, and tx_tnl_segmentation $STATUS"
        echo "taskset -c 1 /usr/bin/netperf -l 5 -H 192.168.10.20 -t ${PROTO}_STREAM -i 10,3 -I 99,5 -- -m $SEND_SIZE -s $SOCKET_SIZE -S $SOCKET_SIZE > ./output/${PROTO}_${STATUS}_${SEND_SIZE}_${SOCKET_SIZE}.bw"
        taskset -c 1 /usr/bin/netperf -l 5 -H 192.168.10.20 -t ${PROTO}_STREAM -i 10,3 -I 99,5 -- -m $SEND_SIZE -s $SOCKET_SIZE -S $SOCKET_SIZE > ./output/${PROTO}_${STATUS}_${SEND_SIZE}_${SOCKET_SIZE}.bw &
        sleep 1s
        sar -P 0 1 10 > ./output/${PROTO}_${STATUS}_${SEND_SIZE}_${SOCKET_SIZE}.cpu &

        echo -n "wait until the test done"
        COUNTER=0
        while [ $COUNTER -lt 55 ]
          do
          let COUNTER++
          echo -n "."
          sleep 1s
        done
        echo
      done
    done
  done
done
