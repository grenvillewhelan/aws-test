#!/bin/bash

LOCATION="westus"
RESOURCE_GROUP_NAME="AIL-${LOCATION}-resource-group"
STORAGE_ACCOUNT_NAME="ailobjectstorage"
CONTAINER_NAME="software"

# Create resource group
az group create \
   --name ${RESOURCE_GROUP_NAME} \
   --location ${LOCATION}

# Create storage account
#az storage account create \
#   --resource-group ${RESOURCE_GROUP_NAME} \
#   --name ${STORAGE_ACCOUNT_NAME} \
#   --sku Standard_LRS \
#   --encryption-services blob

ACCOUNT_KEY=$(az storage account keys list \
                 --resource-group ${RESOURCE_GROUP_NAME} \
                 --account-name ${STORAGE_ACCOUNT_NAME} \
                 --query '[0].value' -o tsv)


# Create blob container
#az storage container create \
#   --name ${CONTAINER_NAME} \
#   --account-key "${ACCOUNT_KEY}" \
#   --account-name ${STORAGE_ACCOUNT_NAME}

#echo ACCOUNT_KEY: ${ACCOUNT_KEY}
#
#az ad sp create-for-rbac --role Contributor --scopes /subscriptions/a892d455-55f8-4480-9e0f-594266d96b54 --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"

