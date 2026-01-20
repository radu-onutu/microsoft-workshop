#!/usr/bin/bash


CleanUp(){
    kubectl delete deploy workload-1-ephemeral workload-3-dynamic-file
    kubectl delete deploy workload-2-disk
    kubectl delete cm configmap-file
    kubectl delete secret secret-simple
    kubectl delete pvc dynamic-file-storage-pvc
}


# Change to the demo folder
cd volumes


read -pr "Navigate to the Namespace"

read -pr "Next Step - Create initial workload with ephemeral volumes"
kubectl apply -f configmap-file.yaml 
kubectl apply -f secret-simple.yaml
kubectl apply -f workload-1-ephemeral.yaml

# $AzureDiskName = read -pr "Enter the Disk Name of the Azure Disk (make sure the cluster identity has rights to disk)" 
# $AzureDiskUri = read -pr "Enter the Resource ID of the Azure Disk" 
# if (($AzureDiskName) -and ($AzureDiskUri)) {
#     SendMessageToCI "Save the name of the Resource ID of an existing Azure Disk" "Save Azure Disk:" "Info"
#     Copy-Item workload-2-disk.yaml temp-disk.yaml
#     (Get-Content -path temp-disk.yaml -Raw) -replace 'AZURE_DISK_NAME', $AzureDiskName | Set-Content -Path temp-disk.yaml
#     (Get-Content -path temp-disk.yaml -Raw) -replace 'AZURE_DISK_URI', $AzureDiskUri | Set-Content -Path temp-disk.yaml
#     read -pr "Next Step - Create deployment with Azure Disk Volume"
#     SendMessageToCI "kubectl apply -f workload-2-disk.yaml" "Kubectl command:" "Command"
#     kubectl apply -f temp-disk.yaml 
#     Remove-Item temp-disk.yaml
# }

read -pr "Next Step - Create deployment with Dynamic Azure File Volume"
kubectl apply -f pvc-dynamic-file.yaml
kubectl apply -f workload-3-dynamic-file.yaml

CleanUp