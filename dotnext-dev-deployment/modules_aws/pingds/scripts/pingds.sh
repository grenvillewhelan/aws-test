#!/bin/bash

export CUSTOMER="${CUSTOMER}"
export DRIVES="${DRIVES}"
export ENVIRONMENT="${ENVIRONMENT}"
export REGION="${REGION}"
export REGION_ALIAS="${REGION_ALIAS}"
export BUILD_VERSION="${BUILD_VERSION}"
export MODULE_VERSION="${MODULE_VERSION}"
export PRODUCT="${PRODUCT}"
export SERVER_INSTANCE="${SERVER_INSTANCE}"
export PRIMARY_PARAMETER_STORES="${PRIMARY_PARAMETER_STORES}"
export DNS_SUFFIX="${DNS_SUFFIX}"
export CLUSTER="${CLUSTER}"
export PRODUCT_NAME="${PRODUCT_NAME}"
export REGION_LIST="${REGION_LIST}"
export CLOUD_PROVIDER="${CLOUD_PROVIDER}"
export CLOUD_PROVIDERS="${CLOUD_PROVIDERS}"
export CLOUD_DNS="${CLOUD_DNS}"
export SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
export SERVER_NAME="pingds-${SERVER_INSTANCE}"

. /opt/AIL/tools/utils.sh

bash /opt/AIL/install/create-volumes.sh '${DRIVES}'

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

bash /opt/AIL/install/ail_base.sh "${CUSTOMER}" "${ENVIRONMENT}" "pingds"

echo
rm /opt/AIL/install/ail_base.sh

echo "Installing PingDS at $(date)"

if [ ! -f "/opt/AIL/install/pingds.sh" ]; then
   echo "$0: Cannot locate /opt/AIL/install/pingds.sh script, cannot continue, exiting."
   exit 1
fi

echo "Running /opt/AIL/install/pingds.sh"
bash /opt/AIL/install/pingds.sh
echo "AIL Base OS Setup complete"

echo "$0: Script completed at $(date)"
