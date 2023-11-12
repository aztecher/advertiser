#!/bin/bash

function setup() {
  mkdir -p ./test-conf
  tee ./test-conf/advertiser.conf <<EOF >/dev/null 2>&1
{
  "cniVersion": "0.4.0",
  "name": "advertiser-test",
  "type": "advertiser",
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.10.0.0/16",
    "routes": [
      {
        "dst": "0.0.0.0/0"
      }
    ]
  }
}
EOF
  sudo ip netns add testing
}

function teardown() {
  sudo rm -rf ./test-conf
  sudo ip netns del testing
}

function cnitest() {
  sudo NETCONFPATH=./test-conf CNI_PATH=../build/ ../bin/cnitool add advertiser-test /var/run/netns/testing
  sudo NETCONFPATH=./test-conf CNI_PATH=../build/ ../bin/cnitool del advertiser-test /var/run/netns/testing
  sudo NETCONFPATH=./test-conf CNI_PATH=../build/ ../bin/cnitool check advertiser-test /var/run/netns/testing
}

setup
cnitest
teardown
