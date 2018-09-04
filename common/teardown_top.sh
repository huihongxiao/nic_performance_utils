#! /bin/bash

ovs-vsctl  del-port br-int tenant1-veth1
ip l del dev tenant1-veth1
ip netns delete tenant1
ovs-vsctl del-port br-int vxlan0
ovs-vsctl del-br br-int
