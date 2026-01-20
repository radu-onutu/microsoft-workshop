#!/usr/bin/bash

CleanUp(){
    kubectl delete deployment workload-dep
    kubectl delete scaledobject cron-scaledobject
    
}

# Change to the demo folder
cd KEDA-Cron


read -pr "Navigate to the Settings page"
read -pr "Turn ON Micro Pods"
read -pr "Navigate to the Deployments page"

read -pr "Next Step - Creates initial workload and Cron KEDA scaler"
kubectl apply -f workload-dep.yaml
kubectl apply -f keda-cron.yaml

read -pr "Observe pod replicas increase every 2nd minute and decrease every 4th minutes"
read -pr "Discuss how this can be used to scale a workload in preparation for a known event"

CleanUp