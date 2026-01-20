#!/usr/bin/bash

CleanUp () {
    kubectl delete svc complex-web-svc
    kubectl delete deploy complex-web-dep
    kubectl delete deploy complex-web-load
    kubectl delete hpa complex-web-hpa-1
}

# Change to the demo folder
cd HPA

read -pr "Navigate to the Settings page"
read -pr "Turn off Mini/Micro Pods so Full sized pods are shown"
read -pr "Turn ON Show Pod Resources"
read -pr "Navigate to the Deployments page"

read -pr "Next Step - Creates initial workload"
kubectl apply -f complex-web-dep.yaml -f complex-web-svc.yaml

read -pr "Wait for Current Metrics to appear in each pod"

read -pr "Next Step - Creates load workload"
kubectl apply -f complex-web-load.yaml

read -pr "Wait for Current Metrics to increase in each pod"

read -pr "Next Step - Increase load instances"
kubectl scale --replicas=15 deploy/complex-web-load

read -pr "Optional - Wait for Current Metrics to increase even more in each pod"

read -pr "Next Step - Creates Horizontal Pod Autoscaler"
kubectl apply -f complex-web-hpa.yaml

read -pr "Click on the Info (i) icon in the HPA to show Behaviors"
read -pr "Wait for number of pods to stabalize"

read -pr "Next Step - Decrease load instances"
kubectl scale --replicas=1 deploy/complex-web-load

read -pr "Wait for number of pods to decrease"

read -pr "Next Step - Delete load instances"
kubectl delete deploy complex-web-load

read -pr "Wait for number of pods to decrease down to 2.  Notice the orignal number of instances was 3"

read -pr "Next Step - Add another metric to HPA to show it can support more than one"
kubectl apply -f complex-web-hpa2.yaml

CleanUp