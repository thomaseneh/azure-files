1. Install Git LFS and push large files
Windows - git lfs install
Ubuntu - sudo apt-get install git-lfs
macOS - brew install git-lfs


2. Track the Large File(s) - git lfs track ".terraform/*"
3.  Add the .gitattributes File - git add .gitattributes
4.  Remove the Large File from Git History - git lfs migrate import --include="Toprefunder-terraform/.terraform/providers/registry.terraform.io/hashicorp/azurerm/4.9.0/darwin_arm64/terraform-provider-azurerm_v4.9.0_x5"
5.  Commit the Changes - git commit -m “text”
6.  git push origin <>

az vmss list-instances --resource-group DevOps --name toprefunderVMSS

az group create --name arm-vscode --location eastus

az deployment group create --resource-group arm-vscode --template-file azuredeploy.json --parameters azuredeploy.parameters.json

az deployment group create -g DevOps -f .json --parameters _artifactsLocation=https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/python/vmss-bottle-autoscale/azuredeploy.json

export ARM_ACCESS_KEY="4Swqwlu78pyXU+zSE0ioBFkRx6PBLUhEXYUEoNCmYjxllErWBs8Gbjvz6N5RBBrRE/CsvMpljh9g+AStxOWF3g=="
az account set --subscription subscription_id
Terraform function
data source: azure _platform_image
Az vm image list —output table —offer Debian-11 —publisher Debian —all

I did not see Snyk in the pipeline	

Between Bridgecrew and Checkov which is most used by devsecops

How do you integrate Checkov into Terraform, CloudFormation, and other IaC

Between Nessus
Qualys and 
OpenVAS which is commonly used by devsecops 


https://www.youtube.com/watch?v=akNSPKX0uIA - Azure Ecommerce

https://www.youtube.com/watch?v=_BTpd2oYafM

https://www.youtube.com/watch?v=z2qRGl9hqBU

https://www.youtube.com/watch?v=QhDnXsmSnfk&t=5s - Multi Cluster Deployment with GitOps 

https://www.youtube.com/watch?v=tstBG7RC9as - AWS Blue green deployment

https://github.com/iam-veeramalla/three-tier-architecture-demo/blob/master/shipping/Dockerfile

* Aks Cluster login (az aks get-credentials  --resource-group <name> —name <AKS Name>)
* Install argoCD
* Configure & UI (1a. Kubectl edit cm argocd-cm, add - data: timeout.reconciliation: 10s, -n argocd, 1. kubectl get svc -n argocd, kubectl edit svc argocd-server -n argocd, change clusterIP - NodePort & save, kubectl get svc -n argocd, copy the http port, kubectl get nodes-o wide & copy the xterna IP, 2. kubectl get secret —n argocd), 3. Kubectl edit secrets <initial-admin-secret> -n argocd, 4. Echo <secret> | base64 —decode, fix inbound rule in VMSS), settings, connect repo, url - repo url & replace name with token & connect, new, 
* Write script (K8s manifest updater)

kubectl create secret docker-registry <secret-name> \
    --namespace <namespace> \
    --docker-server=<container-registry-name>.azurecr.io \
    --docker-username=<service-principal-ID> \
    --docker-password=<service-principal-password>

Secret store csi driver, key vault provider, service account, manage identity

#!/bin/bash

set -x

# Set the repository URL
REPO_URL="https://<ACCESS-TOKEN>@dev.azure.com/<AZURE-DEVOPS-ORG-NAME>/voting-app/_git/voting-app"

# Clone the git repository into the /tmp directory
git clone "$REPO_URL" /tmp/temp_repo

# Navigate into the cloned repository directory
cd /tmp/temp_repo

# Make changes to the Kubernetes manifest file(s)
# For example, let's say you want to change the image tag in a deployment.yaml file
sed -i "s|image:.*|image: <ACR-REGISTRY-NAME>.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml

# Add the modified files
git add .

# Commit the changes
git commit -m "Update Kubernetes manifest"

# Push the changes back to the repository
git push

# Cleanup: remove the temporary directory
rm -rf /tmp/temp_repo


Create Azure Resource Group

az group create --name keyvault-demo --location eastus

AKS Creation and Configuration

Create an AKS cluster with Azure Key Vault provider for Secrets Store CSI Driver support

az aks create --name keyvault-demo-cluster -g keyvault-demo --node-count 1 --enable-addons azure-keyvault-secrets-provider --enable-oidc-issuer --enable-workload-identity

Get the Kubernetes cluster credentials (Update kubeconfig)

az aks get-credentials --resource-group keyvault-demo --name keyvault-demo-cluster

Verify that each node in your cluster's node pool has a Secrets Store CSI Driver pod and a Secrets Store Provider Azure pod running

kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)' -o wide

Keyvault creation and configuration

* Create a key vault with Azure role-based access control (Azure RBAC).
az keyvault create -n aks-demo-abhi -g keyvault-demo -l eastus --enable-rbac-authorization


Connect your Azure ID to the Azure Key Vault Secrets Store CSI Driver

Configure workload identity

export SUBSCRIPTION_ID=fe4a1fdb-6a1c-4a6d-a6b0-dbb12f6a00f8
export RESOURCE_GROUP=keyvault-demo
export UAMI=azurekeyvaultsecretsprovider-keyvault-demo-cluster
export KEYVAULT_NAME=aks-demo-abhi
export CLUSTER_NAME=keyvault-demo-cluster

az account set --subscription $SUBSCRIPTION_ID

Create a managed identity

az identity create --name $UAMI --resource-group $RESOURCE_GROUP

export USER_ASSIGNED_CLIENT_ID="$(az identity show -g $RESOURCE_GROUP --name $UAMI --query 'clientId' -o tsv)"
export IDENTITY_TENANT=$(az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --query identity.tenantId -o tsv)

Create a role assignment that grants the workload ID access the key vault

export KEYVAULT_SCOPE=$(az keyvault show --name $KEYVAULT_NAME --query id -o tsv)

az role assignment create --role "Key Vault Administrator" --assignee $USER_ASSIGNED_CLIENT_ID --scope $KEYVAULT_SCOPE

Get the AKS cluster OIDC Issuer URL

export AKS_OIDC_ISSUER="$(az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"
echo $AKS_OIDC_ISSUER

Create the service account for the pod

export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_NAMESPACE="default" 

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_CLIENT_ID}
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF

Setup Federation

export FEDERATED_IDENTITY_NAME="aksfederatedidentity" 

az identity federated-credential create --name $FEDERATED_IDENTITY_NAME --identity-name $UAMI --resource-group $RESOURCE_GROUP --issuer ${AKS_OIDC_ISSUER} --subject system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}

Create the Secret Provider Class

cat <<EOF | kubectl apply -f -
# This is a SecretProviderClass example using workload identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-wi # needs to be unique per namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    clientID: "${USER_ASSIGNED_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KEYVAULT_NAME}       # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: secret1             # Set to the name of your secret
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
        - |
          objectName: key1                # Set to the name of your key
          objectType: key
          objectVersion: ""
    tenantId: "${IDENTITY_TENANT}"        # The tenant ID of the key vault
EOF

Verify Keyvault AKS Integration

Create a sample pod to mount the secrets

cat <<EOF | kubectl apply -f -
# This is a sample pod definition for using SecretProviderClass and workload identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-wi
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: "workload-identity-sa"
  containers:
    - name: busybox
      image: registry.k8s.io/e2e-test-images/busybox:1.29-4
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-kvname-wi"
EOF

List the contents of the volume

kubectl exec busybox-secrets-store-inline-wi -- ls /mnt/secrets-store/

Verify the contents in the file

kubectl exec busybox-secrets-store-inline -- cat /mnt/secrets-store/foo-secret

Kubectl config current-context 

