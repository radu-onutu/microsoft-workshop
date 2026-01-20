#!/usr/bin/bash

CleanUp(){
    kubectl delete deploy init-dep
}

# Change to the demo folder
cd InitContainers


read -pr "Navigate to the Deployments Page"

read -pr "Next Step - Creates a multi-container workload with Init Containers"
kubectl apply -f init-dep.yaml

read -pr "Click on any of the new pods to view Pod Details.  Watch the containers tabs"

CleanUp
