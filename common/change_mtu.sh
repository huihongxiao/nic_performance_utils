#!/bin/bash


if [ $# -ne 1 ]; then
    echo "MTU should be specified."
    exit 1
fi

MTU=$1

ip l set dev eth0 mtu $MTU
ip l set dev tenant1-veth1 mtu $MTU

VXLAN_MTU=`expr $MTU - 50`
ip netns exec tenant1 ip l set dev tenant1-veth0 mtu $VXLAN_MTU
