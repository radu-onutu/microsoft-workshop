#!/usr/bin/bash

CleanUp(){
    kubectl delete deploy multi-dep
}

# Change to the demo folder
cd MultiContainerPods

read -pr "Navigate to the Deployments Page"

read -pr "Next Step - Creates multi-container workload with 1 container that doesn't start and 1 that fails after a while"
kubectl apply -f multi-dep.yaml

read -pr "Click on any of the new pods to view Pod Details.  Watch the containers tabs"

CleanUp