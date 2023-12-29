#!/bin/bash

FAILED_FLAG=1

function confirm_pod() {
  # Try to get pod status will be 'Running' in 30 secs.
  for i in `seq 1 120`;
  do
    STATUS=$(kubectl get pod netshoot-secondary-veth --no-headers | awk '{print $3}')
    if [[ "${STATUS}" == "Running" ]]; then
      echo "[+] Pod status is '${STATUS}'"
      FAILED_FLAG=0
      break
    fi
    echo "[-] Pod status is '${STATUS}', waiting for 'Running'"
    sleep 1;
  done
}

confirm_pod
if [[ $FAILED_FLAG -ne 0 ]]; then
  echo "[!] Failed to startup Pod, here is the details..."
  kubectl describe pod netshoot-secondary-veth
fi
