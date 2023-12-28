#!/bin/bash

# For Github Actions
NOSUDO=$1

function require_sudo() {
  if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
  fi
}

function setup_kind_netns() {
  for i in $(docker container ls --format "{{.ID}}");
  do
    PID=$(docker inspect -f '{{.State.Pid}}' $i)
    NAME=$(docker inspect -f '{{.Name}}' $i | tr -d '/')
    # skip a container that it's name isn't contains the 'k8sdev'
    if [[ "$NAME" != *k8sdev* ]]; then
      echo "[-] Skip ${NAME} container ns association"
      continue
    fi
    echo "[+] Create symlink: /proc/${PID}/ns/net /var/run/netns/${NAME}"
    sudo ln -s /proc/${PID}/ns/net /var/run/netns/${NAME}
  done

  echo "[+] You can find ns as it's name. Please execute 'ip netns list' command."
}

if [[ "$NOSUDO" != "nosudo" ]]; then
  require_sudo
fi
setup_kind_netns
