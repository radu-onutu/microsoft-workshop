#!/usr/bin/bash

CleanUp(){
    kubectl delete deploy -l app=demo
    kubectl delete service probes-svc
}

# Change to the demo folder
cd Probes


read -pr "Navigate to the Settings page"
read -pr "Turn OFF Mini and Micro Pods"
read -pr "Turn ON Show Containers"
read -pr "Navigate to the Namespace"

read -pr "Next Step - Creates a Startup Probes"
kubectl apply -f probes-svc.yaml
kubectl apply -f dep-startup-probe.yaml

read -pr "Review how the Pod never reaches a Ready state even though it's Running"
read -pr "Wait a minute or two and see the how the Restart count increases"
read -pr "Navigate to the Services and see how it's not available"

read -pr "Navigate to the Namespace"
read -pr "Next Step - Create a Liveness Probe"
kubectl apply -f dep-liveness-probe.yaml

read -pr "After the Pod is ready, navigate to the Services and see how it's available"
read -pr "Wait for a minute or two.  See how it restarts the container, but it stays available"

read -pr "Navigate to the Namespace"
read -pr "Next Step - Create a Readiness Probe"
kubectl apply -f dep-readiness-probe.yaml

read -pr "Navigate to the Services and see how it's not available for about a minute then shows up"

CleanUp