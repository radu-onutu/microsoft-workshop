#!/usr/bin/bash

CleanUp(){
    kubectl delete deploy -l scope=demo
    kubectl label node $selectedNode color-
    kubectl label node $selectedNode allowedprocess-
    kubectl taint node $selectedNode onlyprocess-
}

# Change to the demo folder
cd TaintsTolerations


read -pr "Navigate to the Settings page"
read -pr "Turn ON Mini or Micro Pods"
read -pr "Navigate to the Nodes page" </dev/tty

read -pr "Next Step - Creates initial workloads" </dev/tty
kubectl apply -f workload-1.yaml -f workload-2.yaml -f workload-3.yaml

read -pr "Enter the Node Name of one node" selectedNode
echo $selectedNode
 aks-agentpool-31289776-vmss000004
read -pr "Next Step - Adds color and Process label to Node" </dev/tty
kubectl label node $selectedNode color=lime --overwrite
kubectl label node $selectedNode allowedprocess=gpu --overwrite

read -pr "Notice the color box appear in the Node"

read -pr "Next Step - Adds Node Selector to Lime deployment" </dev/tty
kubectl apply -f workload-1-node-selector.yaml

read -pr "Wait for all the Lime pods to be rescheduled on the selected node" </dev/tty

read -pr "Next Step - Adds Taint to Node"
kubectl taint node $selectedNode onlyprocess=gpu:NoSchedule

read -pr "Delete all the Pods on the Node" </dev/tty
kubectl delete pods --field-selector=spec.nodeName=$selectedNode

read -pr "Wait for ALL pods to be evicted from selected node" </dev/tty

read -pr "Observe how Lime pods cannot be scheduled.  Examine their events" </dev/tty

read -pr "Next Step - Adds Toleration to Lime deployment" </dev/tty
kubectl apply -f workload-1-toleration.yaml

read -pr "Observe how only the Lime pods are scheduled on selected node and all others are on other nodes" </dev/tty

CleanUp