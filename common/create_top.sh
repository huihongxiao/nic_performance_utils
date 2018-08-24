#! /bin/bash

REMOTE_IP=10.23.21.90
LOCAL_VIP=192.168.10.10/24

if ! [ -x "$(command -v ovs-vsctl)" ]; then
    echo 'Error: openvswitch is not installed.'
    apt upate -y
    apt install -y openvswitch-switch
fi

# Create bridge
ovs-vsctl add-br br-int

# Create VXLAN interface and set destination VTEP
ovs-vsctl add-port br-int vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=${REMOTE_IP} options:key=10 options:dst_port=4789

# Create tenant namespaces
ip netns add tenant1

# Create veth pairs
ip link add tenant1-veth0 type veth peer name tenant1-veth1

# Link primary veth interfaces to namespaces
ip link set tenant1-veth0 netns tenant1

# Add IP addresses
ip netns exec tenant1 ip a add dev tenant1-veth0 ${LOCAL_VIP}

# Bring up loopback interfaces
ip netns exec tenant1 ip link set dev lo up

# Set MTU to account for VXLAN overhead
ip netns exec tenant1 ip link set dev tenant1-veth0 mtu 1450

# Bring up veth interfaces
ip netns exec tenant1 ip link set dev tenant1-veth0 up

# Bring up host interfaces and set MTU
ip link set dev tenant1-veth1 up
ip link set dev tenant1-veth1 mtu 1500

# Attach ports to OpenvSwitch
ovs-vsctl add-port br-int tenant1-veth1
