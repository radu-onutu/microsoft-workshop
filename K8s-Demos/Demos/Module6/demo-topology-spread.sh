#!/usr/bin/bash

CleanUp(){
    kubectl delete deploy workload
}

# Change to the demo folder
cd TopologySpread

read -pr "This demo assumes you have 3 nodes" </dev/tty
read -pr "Navigate to the Settings page.  Turn on Micro Pods"
read -pr "Navigate to the Nodes page" </dev/tty

read -pr "Next Step - Create the initial workflow with 3 replicas" </dev/tty
kubectl apply -f workload.yaml
read -pr "Notice how Pods are evenly spread out across the nodes" </dev/tty

read -pr "Next Step - Increases workload to 12 instances" </dev/tty
kubectl scale --replicas=12 deploy/workload
read -pr "Notice how Pods are still being evenly spread out across the nodes" </dev/tty

read -pr "Next Step - Increases workload to 22 instances" </dev/tty
kubectl scale --replicas=19 deploy/workload
read -pr "Notice how Pods are still being evenly spread out WITHOUT exceeing MaxSkew" </dev/tty

read -pr "Next Step - Decrease workload instances again" </dev/tty
kubectl scale --replicas=6 deploy/workload
read -pr "Notice how Pods may NOT be deleted evenly between the nodes" </dev/tty
read -pr "This constraint only works during scheduling, not deletions." </dev/tty

read -pr "Next Step - Increases workload to 45 instances, which is more than 3 nodes can support" </dev/tty
kubectl scale --replicas=45 deploy/workload
read -pr "The auto scaler should start creating additional nodes" </dev/tty
read -pr "Notice how some Pods are still pending but there's still room on some nodes" </dev/tty
read -pr "This is because MaxSkew is set to 1, so there can be no more than 1 pod count difference between nodes" </dev/tty
read -pr "Remaining Pods will be scheduled on new node, even though there will" </dev/tty
read -pr "be a difference higher than MaxSkew.  It will NOT rebalance the Nodes." </dev/tty
read -pr "Some Pods may stay Pending, even though there's room on some of the Nodes." </dev/tty
read -pr "Again this is because of MaxSkew" </dev/tty

read -pr "Next Step - Set MaxSkew to 3 and patch the deployment" </dev/tty
kubectl patch deploy workload --patch-file patch-maxskew-3.yaml
read -pr "The scheduler will now redeploy the pods (new replica set) and allow a difference of 3 Pods between nodes" </dev/tty

read -pr "Next Step - Set MaxSkew to 1, WhenUnsatisfiable to ScheduleAnyway.  Patch the deployment" </dev/tty
kubectl patch deploy workload --patch-file patch-schedule-anyway.yaml
read -pr "The scheduler will now redeploy the pods and allow all Pods to be scheduled regardless of MaxSkew"
read -pr "This setting is not very different from not having any constraints at all" </dev/tty

CleanUp