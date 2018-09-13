#! /bin/bash

source ./var_rc

source ~/admin-openrc

if [ $# -eq 2 ]; then
    SIZE=$1
    MSG_SIZE=$2 
fi

# Create neutron tenant network
openstack network show $NET_NAME
if [ $? -eq 0 ]; then
    echo "There is stale network existing, delete it before proceeding."
    exit 1
fi

openstack network create $NET_NAME --mtu 1500
openstack subnet create --network $NET_NAME --subnet-range $CIDR $SUBNET_NAME
echo -e "\n\n\nNetwork $NET_NAME with CIDR $CIDR has been created."

# Create netperf servers on 78
for((i = 1; i <= $SIZE; i++))
do
    echo -e "\n\n\nCreating $i netperf server."
    ip_addr=`expr $SERVER_START_ADDR + $i`
    port_uuid=$(openstack port create $SERVER_PORT_NAME_PREFIX$ip_addr --network $NET_NAME --fixed-ip ip-address=${CIDR_NET_ADDR}${ip_addr} | awk '$2=="id" {print $4}' | head -n 1)
    echo -e "Port $port_uuid has been created."
    nova boot --flavor $FLAVOR --image $IMAGE_UUID --key-name $KEY_NAME --availability-zone nova:$SERVER_HOST --nic port-id=$port_uuid --config-drive true --user-data $SERVER_USER_DATA $SERVER_NAME_PREFIX$i
done

wait_s=0
if (( $SIZE < 15 ))
then
    wait_s=`expr 15 - $SIZE`
fi
echo -e "\nWait ${wait_s}s for server to be ready"
for((i = 1; i <= $wait_s; i++))
do
    sleep 1s
    echo -n "."
done

# Create netperf clients on 79
for((i = 1; i <= $SIZE; i++))
do
    echo -e "\n\n\nCreating $i netperf client."
    ip_addr=`expr $CLIENT_START_ADDR + $i`
    server_ip_addr=`expr $SERVER_START_ADDR + $i`
    port_uuid=$(openstack port create $CLIENT_PORT_NAME_PREFIX$ip_addr --network $NET_NAME --fixed-ip ip-address=${CIDR_NET_ADDR}${ip_addr} | awk '$2=="id" {print $4}' | head -n 1)
    echo -e "Port $port_uuid has been created."
    sh ./client_data_generater.sh ${CIDR_NET_ADDR}${server_ip_addr} $MSG_SIZE $TEST_TIME > temp_${CIDR_NET_ADDR}${ip_addr}
    nova boot --flavor $FLAVOR --image $IMAGE_UUID --key-name $KEY_NAME --availability-zone nova:$CLIENT_HOST --nic port-id=$port_uuid --config-drive true --user-data ./temp_${CIDR_NET_ADDR}${ip_addr} $CLIENT_NAME_PREFIX$i
done

echo -e "\n\n\nVNC links...."

wait_s=0
if (( $SIZE < 15 ))
then
    wait_s=`expr 15 - $SIZE`
fi
echo -e "\nWait ${wait_s}s for clients to be ready"
for((i = 1; i <= $wait_s; i++))
do
    sleep 1s
    echo -n "."
done

echo

# Print out novnc links for clients on 79
for((i = 1; i <= $SIZE; i++))
do
    echo "$CLIENT_NAME_PREFIX$i:    "
    echo -n $(nova get-vnc-console $CLIENT_NAME_PREFIX$i novnc | awk '/novnc/ {print $4}')
    echo
done

echo -e "\nWait 120s for clients boot up"
for((i = 1; i <= 120; i++))
do
    sleep 1s
    echo -n "."
done

# Measure the CPU usage on 79,78
nohup ssh 10.17.33.79 sar 1 50 > 10_17_33_79_${SIZE}_${MSG_SIZE}.cpu &


nohup ssh 10.17.33.78 sar 1 50 > 10_17_33_78_${SIZE}_${MSG_SIZE}.cpu &

echo -e "\nWait 50s for sar to complete cpu measurment."
for((i = 1; i <= 50; i++))
do
    sleep 1s
    echo -n "."
done

sleep 5s
