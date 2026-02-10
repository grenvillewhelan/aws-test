#!/bin/bash

REGION=$1
CLIENT_ID=$2
CLIENT_SECRET=$3
TENANT_ID=$4

CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   echo -n "Logging into Azure: "
   az login --service-principal \
            --username ${CLIENT_ID} \
            --password ${CLIENT_SECRET} \
            --tenant ${TENANT_ID} | jq -r '.[].cloudName'
fi

echo 

export DEBIAN_FRONTEND=noninteractive

sudo mkdir -p /opt/ansible/roles \
              /opt/ansible/group_vars \
              /opt/ansible/files

sudo useradd -m -r -s /bin/bash ansible

echo "Installing Ansible"
echo "===================================== $(date)"
echo

echo "Running: sudo apt update && apt upgrade -y"
sudo -E apt-get update

echo
echo "===================================== $(date)"
echo

echo "Running: sudo apt install software-properties-common -y"
sudo -E apt-get install -y -qq software-properties-common python3-pip

echo
echo "===================================== $(date)"
echo

echo "Running: sudo add-apt-repository --yes --update ppa:ansible/ansible"
sudo add-apt-repository --yes --update ppa:ansible/ansible

echo
echo "===================================== $(date)"
echo

echo "Running: sudo apt install ansible -y"
sudo apt-get install -y -qq ansible

sudo pip3 install 'pyvmomi'
sudo pip3 install 'azure-mgmt-compute'

echo
echo "===================================== $(date)"
echo

echo "Running: ansible-galaxy collection install azure.azcollection"
sudo -u ansible ansible-galaxy collection install azure.azcollection
echo "Running: ansible-galaxy collection install community.vmware"
sudo -u ansible ansible-galaxy collection install community.vmware
echo "Running: ansible-galaxy collection install community.general"
sudo -u ansible ansible-galaxy collection install community.general

sudo -E apt-get install -y -qq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ansible

sudo chown -R ansible:ansible /opt/ansible
sudo chmod -R 750 /opt/ansible
echo
echo "===================================== $(date)"
echo "Completed"
echo
