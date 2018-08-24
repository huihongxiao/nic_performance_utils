#! /bin/bash

if ! [ -x "$(command -v netserver)" ]; then
  echo 'Error: netperf is not installed.'
  apt update -y
  apt install -y netperf
fi

netserver -4 -D
