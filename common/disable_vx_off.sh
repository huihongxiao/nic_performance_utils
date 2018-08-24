#! /bin/bash

ethtool -K eth0 tx-udp_tnl-segmentation off
ethtool -K eth0 tx-udp_tnl-csum-segmentation off
ethtool -k eth0 | grep tnl
