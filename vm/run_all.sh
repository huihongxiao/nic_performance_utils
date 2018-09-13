#! /bin/bash

set -e

MSG_SIZES="4096"
VM_SIZES="40 45 50"

for MSG in $MSG_SIZES
do
    for VM_SIZE in $VM_SIZES
    do
        echo "==============================================="
        echo "Run test with TCP message size $MSG and $VM_SIZE pairs of VMs"
        ./run_test.sh $VM_SIZE $MSG
        sleep 5s
        ./clean_env.sh $VM_SIZE
        sleep 5s
    done
done
