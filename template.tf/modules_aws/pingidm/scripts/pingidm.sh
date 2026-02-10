#!/bin/bash

export CUSTOMER="${CUSTOMER}"
export ENVIRONMENT="${ENVIRONMENT}"
export REGION="${REGION}"
export REGION_ALIAS="${REGION_ALIAS}"
export BUILD_VERSION="${BUILD_VERSION}"
export MODULE_VERSION="${MODULE_VERSION}"
export PRODUCT="${PRODUCT}"
export SERVER_INSTANCE="${SERVER_INSTANCE}"
export PRIMARY_PARAMETER_STORES="${PRIMARY_PARAMETER_STORES}"
export LOG_RETENTION="${LOG_RETENTION}"
export DNS_SUFFIX="${DNS_SUFFIX}"
export LDIF_BACKUP_TIME="${LDIF_BACKUP_TIME}"
export PD_BACKUP_TIME="${PD_BACKUP_TIME}"
export PD_BACKUP_STAGGER_MINS="${PD_BACKUP_STAGGER_MINS}"
export REGION_BACKUP_START_DELAY="${REGION_BACKUP_START_DELAY}"
export CLUSTER="${CLUSTER}"
export PRODUCT_NAME="${PRODUCT_NAME}"
export BACKUP_PREFIX="${BACKUP_PREFIX}"
export PF_CLUSTER="${PF_CLUSTER}"
export TENANT_ID="${TENANT_ID}"
export CLIENT_ID="${CLIENT_ID}"
export CLIENT_SECRET="${CLIENT_SECRET}"
export REGION_LIST="${REGION_LIST}"
export CLOUD_PROVIDER="${CLOUD_PROVIDER}"
export CLOUD_PROVIDERS="${CLOUD_PROVIDERS}"
export CLOUD_DNS="${CLOUD_DNS}"
export PINGDIRECTORY_BASE_DN="${PINGDIRECTORY_BASE_DN}"
export PINGDIRECTORY_UNDERSCORE_BASE_DN="${PINGDIRECTORY_UNDERSCORE_BASE_DN}"
export SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"

. /opt/AIL/tools/utils.sh

(create_banner "${PRODUCT_NAME}"
 create_banner "@ ${REGION_ALIAS}"
   echo
   echo "                   Built by AccessIndentified Infrastructure Automation"
   echo
   echo "                   AMI Build Version: ${BUILD_VERSION}"
   echo
   echo "              Server: ${PRODUCT_NAME}  Region: ${REGION}  Cluster: ${CLUSTER}"
   echo
   echo "                    Deployed at $(date)"
) >> /etc/motd

bash /opt/AIL/install/ail_base.sh "${CUSTOMER}" "${ENVIRONMENT}" "pingidm"

echo
rm /opt/AIL/install/ail_base.sh

echo "Installing PingIDM at $(date)"

if [ ! -f "/opt/AIL/install/pingidm.sh" ]; then
   echo "$0: Cannot locate /opt/AIL/install/pingidm.sh script, cannot continue, exiting."
   exit 1
fi

echo "Running /opt/AIL/install/pingidm.sh"
bash /opt/AIL/install/pingidm.sh
echo "AIL Base OS Setup complete"

echo "$0: Script completed at $(date)"
