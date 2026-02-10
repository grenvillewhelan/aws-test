#!/bin/bash

CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)

if [ -f /opt/AIL/tools/utils.sh ]; then
   . /opt/AIL/tools/utils.sh
else
   echo "$0: Cannot read /opt/AIL/tools/utils.sh, exiting."
   exit 1
fi

export cloud_provider=${CLOUD_PROVIDER}
export cloud_providers=$(jq -n ${CLOUD_PROVIDERS} | jq -r '. | join(" ")')
server_number=${SERVER_INSTANCE}

export LOC_DIR="/opt/opendj"

echo "$0: running pingds.sh $*"

if [ ! -d "${LOC_DIR}" ]; then
  echo "$0: cannot locate ${LOC_DIR}"
fi

DS_USER="ubuntu"
chown -R "${DS_USER}:${DS_USER}" ${LOC_DIR}

#echo "Running PingDS setup"
#echo
#
#if [ -n "$(echo ${cloud_providers} | grep azure)" ]; then
#   if [ -n "$(echo ${cloud_providers} | grep aws)" ]; then
#      echo "Primary Parameter Store on AWS for Azure instances"
#   else
#      echo "Primary Parameter Store on Azure for Azure instances"
#   fi
#else
#   echo "Primary Parameter Store on AWS for AWS instances"
#fi
#
#DEPLOYMENT_PASSWORD="0fucuky@Fr1ed"
#ROOT_PASSWORD="root123!"
#MONITOR_USER_PASSWORD="monitor123!"
#AM_CONFIG_PASSWORD="87g3gh@fde%fFD"
#AM_STORE_PASSWORD="fre%TRG-Xc9fds"

echo "$(date): hostname is $(hostname)"
cd ${LOC_DIR}

#DEPLOYMENT_ID=$(./bin/dskeymgr create-deployment-id --deploymentIdPassword "${DEPLOYMENT_PASSWORD}")
#
#echo "$(date): dskeymgr returned $?"
#echo "DEPLOYMENT_ID is : ${DEPLOYMENT_ID}"
#
#./setup \
#  --acceptLicense \
#  --deploymentId "${DEPLOYMENT_ID}" \
#  --deploymentIdPassword "${DEPLOYMENT_PASSWORD}" \
#  --set am-config/amConfigAdminPassword:"${AM_CONFIG_PASSWORD}" \
#  --set am-identity-store/amIdentityStoreAdminPassword:"${AM_STORE_PASSWORD}" \
#  --profile am-config \
#  --profile am-identity-store \
#  --profile idm-repo \
#  --hostname $(hostname) \
#  --ldapPort 1389 \
#  --adminConnectorPort 4444 \
#  --instancePath $(pwd) \
#  --rootUserDN "cn=Directory Manager" \
#  --rootUserPassword "${ROOT_PASSWORD}" \
#  --monitorUserPassword "${MONITOR_USER_PASSWORD}" \
#  --acceptLicense \
#  --start
#
#echo "$(date): setup returned $?"
#
#echo "${VERSION}" > ${LOC_DIR}/.version

update_name_tag "${SERVER_TYPE}-running"

echo "$0: Completed at $(date)"
