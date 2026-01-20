#!/usr/bin/bash

CleanUp(){
    kubectl delete job countdown-job
    kubectl delete cronjob sample-cron-job
}

# Change to the demo folder
cd Jobs


read -pr "Navigate to the Jobs page"

read -pr "Next Step - Creates a Job"
kubectl apply -f countdown-job.yaml

read -pr "Next Step - Create a Cron Job"
kubectl apply -f sample-cron-job.yaml

read -pr "Click on the Cron Jobs tab.  Wait for new jobs to show up.  Will maintain history of past 3 jobs"

CleanUp