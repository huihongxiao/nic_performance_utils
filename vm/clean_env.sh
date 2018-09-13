#! /bin/bash

source var_rc
source ~/admin-openrc

if [ $# -eq 1 ]; then
    SIZE=$1
fi

# Delete netperf servers.
echo -e "\n\n\nDeleting netperf servers..."
for((i = 1; i <= $SIZE; i++))
do
    nova delete $SERVER_NAME_PREFIX$i
    echo -e "\nServer $SERVER_NAME_PREFIX$i has been deleted."
done

# Delete netperf clients.
echo -e "\n\n\nDeleting netperf clients..."
for((i = 1; i <= $SIZE; i++))
do
    nova delete $CLIENT_NAME_PREFIX$i
    echo -e "\nClient $CLIENT_NAME_PREFIX$i has been deleted."
done

# Wait nova to unplug vif.
echo -e "\n Wait 10S for nova to unplug vifs..."
sleep 10s

# Since neutron ports are created explictly, they need to be deleted explictly.
echo -e "\n\n\nDeleting ports..."
# Delete server ports
for((i = 1; i <= $SIZE; i++))
do
    ip_addr=`expr $SERVER_START_ADDR + $i`
    openstack port delete $SERVER_PORT_NAME_PREFIX$ip_addr
    echo -e "Port $SERVER_PORT_NAME_PREFIX$ip_addr has been deleted."
done

# Delete clients ports 
for((i = 1; i <= $SIZE; i++))
do
    ip_addr=`expr $CLIENT_START_ADDR + $i`
    openstack port delete $CLIENT_PORT_NAME_PREFIX$ip_addr
    echo -e "Port $CLIENT_PORT_NAME_PREFIX$ip_addr has been deleted."
done

#port_list=$(openstack port list --network $NET_NAME | awk '/[0-9,a-f]8/ {print $2}')
#for port in $port_list
#do
#    openstack port delete $port
#    echo -e "\nPort $port has been deleted."
#done

openstack network delete $NET_NAME
echo -e "\nNetwork $NET_NAME has been deleted."

echo -e "\n\n\nClean temp userdata file."
rm -f temp_*
