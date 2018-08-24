#!/bin/bash

NIC=eth0

if [ $# -eq 1 ]; then
    NIC=$1
fi

# (1) Just set one queue for eth0
# ethtool -L eth0
# no channel parameters changed, aborting
# current values: tx 0 rx 0 other 1 combined 48

echo -e "Step1: Only set one queue for $NIC\n====================================\n"
ethtool -L $NIC
ethtool -L $NIC combined 1


# (2) Tie irp to cpu0, use the famous set_irq_affinity.sh for the job
echo -e "\n\n\n\n\n\nStep2: Tie $NIC irp handler to CPU0\n====================================\n"
if [ ! -f "./set_irq_affinity.sh" ]; then
    echo "set_irq_affinity.sh not exist. Download it..."
    wget https://gist.githubusercontent.com/SaveTheRbtz/8875474/raw/0c6e500e81e161505d9111ac77115a2367180d12/set_irq_affinity.sh
    chmod u+x set_irq_affinity.sh
fi

./set_irq_affinity.sh 0 $NIC


# (3) Make processors stick to the C0 C-state
echo -e "\n\n\n\n\n\nStep3: Make processors stick to the C0 C-state\n====================================\n"
if [ ! -f "setcpulatency.c" ]; then
    echo "setcpulatency.c not exist. Download it..."
    wget https://raw.githubusercontent.com/gtcasl/hpc-benchmarks/master/setcpulatency.c
    make setcpulatency
fi
./setcpulatency 0 &
echo -e "Make sure to kill the process from \"ps -ef | grep latency\""

# (4) Set the cpu power state to "performance"
# Failed to do that, as 4.4 kernal doesn't have this file.
echo -e "\n\n\n\n\n\nStep4: Set all cpu to max performace\n====================================\n"
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

