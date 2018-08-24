#! /bin/bash

ethtool -K eth0 tx-udp_tnl-segmentation on
ethtool -K eth0 tx-udp_tnl-csum-segmentation on
ethtool -k eth0 | grep tnl
