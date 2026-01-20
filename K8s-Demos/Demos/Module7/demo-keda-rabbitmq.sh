#!/usr/bin/bash

CleanUp(){
    kubectl delete -f .
}

# Change to the demo folder
cd KEDA-RabbitMQ


read -pr "Navigate to the Settings page"
read -pr "Turn ON Micro Pods"
read -pr "Navigate to the Deployments page"

read -pr "Next Step - Creates initial workloads"
kubectl apply -f rabbit-cm.yaml
kubectl apply -f rabbit-dep.yaml
kubectl apply -f rabbit-svc.yaml
kubectl apply -f queue-processor.yaml

read -pr "Wait until Rabbit workload is ready"

read -pr "Load rabbit UI - In a background job"
read -pr  " run in another window kubectl port-forward svc/rabbit-svc 15672 "

read -pr "Open a browser window and navigate to http://localhost:15672"
read -pr "Observer SampleQueue on the Queues page"

read -pr "Next Step - Loads Messages into queue"
kubectl apply -f queue-loader-job.yaml

read -pr "Observer about 500 message in SampleQueue on the Queues page"
read -pr "Observer how slowly they're being processed"

read -pr "Next Step - Creates KEDA autoscaler"
kubectl apply -f keda-rabbit.yaml

read -pr "Observer increase in pod replicas.  Show HPA Info (i) panel.  Observe Scale Down Stabilization Window"
read -pr "Observer pod replica decrease as queued messages decrease"

CleanUp