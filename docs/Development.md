# Development

This document contains how to construct the testbed.

This configuration applied in Github Action's CI workflow

## Prerequisites

- docker
- kind
- containerlab

### Basic Setup

First of all, create kind cluster with no-CNI

```bash
kind create cluster --name k8sdev --config e2e/manifests/kind-k8sdev-no-cni.yaml
```

After creating cluster, apply flannel CNI manifest and multus CNI manifest.

```bash
# Deploy flannel as a primary CNI
kubectl apply -f e2e/manifests/kube-flannel.yaml
# Deploy multus as a meta plugin
kubectl apply -f e2e/manifests/multus-daemonset-thick.yaml
```

### Create external network

After creating kind cluster, also create external network by containerlab.
Download clab container and execute 'containerlab deploy' command in that container.

```bash
docker pull ghcr.io/srl-labs/clab
docker run --rm -it --privileged \
    --network host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/run/netns:/var/run/netns \
    -v /etc/hosts:/etc/hosts \
    -v /var/lib/docker/containers:/var/lib/docker/containers \
    --pid="host" \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    ghcr.io/srl-labs/clab bash

containerlab deploy --network kind --topo e2e/clab/sample-topology.yaml
```

### Step1. Basic Testbed

As the basic testbed, create the L2 network to connect external network and k8sdev-worker.  
For more details, configure the following settings.

1. Create veth pair in default network and pass one of these to external network ns and another to k8sdev-worker.
2. 

```bash
# Default, ip netns cannot reachout the kind-node's netns because it's not linked to /var/run/netns,
# So, statically link it.
sudo e2e/scripts/setup_kind_netns.sh

# Create veth pair in host-system, and pass it to containerlab netns and k8sdev-worker netns
sudo ip link add from-leaf type veth peer name to-leaf
sudo ip link set to-leaf netns clab-sample-topology-leaf
sudo ip link set from-leaf netns k8sdev-worker

# Setup network on each netns
# In containerlab netns, assign IP address and linkup
sudo ip netns exec clab-smaple-topology-leaf ip addr add 192.168.0.11/24 dev to-leaf
sudo ip netns exec clab-sample-topology-leaf ip link set to-leaf up

# In k8sdev-worker netns, setup network by following steps.
# 1. Create bridge
sudo ip netns exec k8sdev-worker ip link add br-secondary type bridge
# 2. Create another veth pair in k8sdev-worker
sudo ip netns exec k8sdev-worker ip link add from-pod type veth peer name to-pod
# 3. Assign two veth pair to the bridge
sudo ip netns exec k8sdev-worker ip link set dev from-pod master br-secondary
sudo ip netns exec k8sdev-worker ip link set dev from-leaf master br-secondary
# 4. Assign IP address to one of the veth created in k8sdev-worker.
sudo ip netns exec k8sdev-worker ip adr add 192.168.0.10/24 dev to-pod
# 5. Linkup each devices.
sudo ip netns exec k8sdev-worker ip link set br-secondary up
sudo ip netns exec k8sdev-worker ip link set from-leaf up
sudo ip netns exec k8sdev-worker ip link set from-pod up
sudo ip netns exec k8sdev-worker ip link set to-pod up
```

After above configuration, test reachability from containerlab to k8sdev-worker's veth over L2 bridge.

```bash
# Test reachability
sudo ip netns exec clab-sample-topology-leaf ping -c 1 192.168.0.10
```

### Step2. Advanced Testbed

Advanced testbed allows the to-pod veth in Basic testbed to be actually assigned to a pod to check for sparsity.

First, delete the assigned IP address of the to-pod's veth.  

```bash
sudo ip netns exec k8sdev-worker ip addr del 192.168.0.10/24 dev to-pod
```

After that, prepare NetworkAttachmentDefinition that simply assigns this veth to the pod.

```bash
cat e2e/manifests/net-attach-def-veth01.yaml  TSTP ✘ │ 21m 47s │   │ 01:30:30
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: net-attach-def-veth01
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "host-device",
      "device": "to-pod",
      "ipam": {
        "type": "static",
        "addresses": [
          {
            "address": "192.168.0.10/24"
          }
        ]
      }
    }'
```

create above NetworkAttachmentDefinition and Pod that uses this net-attach-def.  

```bash
kubectl apply -f e2e/manifests/net-attach-def-veth01.yaml
kubectl apply -f e2e/manifests/pod-netshoot-veth01.yaml
```

After the pod status is Running, check reachability from containerlab to pod.

```bash
sudo ip netns exec clab-sample-topology-leaf ping -c 1 192.168.0.10
```
