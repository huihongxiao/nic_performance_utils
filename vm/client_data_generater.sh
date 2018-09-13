#!/bin/sh

SERVER_IP=$1
MSG_SIZE=$2
TEST_TIME=$3

#define the template.
cat  << EOF
#cloud-config
password: passw0rd
chpasswd: { expire: False }
ssh_pwauth: True

runcmd:
  - /usr/bin/netperf -l $TEST_TIME -H $SERVER_IP -t TCP_STREAM -i 10,3 -I 99,5 -- -m $MSG_SIZE -s 4M -S 4M > ./TCP.bw
EOF
