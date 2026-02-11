#!/bin/bash

export BUILD_VERSION="${BUILD_VERSION}"
export REGION="${REGION}"
export REGION_ALIAS="${REGION_ALIAS}"
export CUSTOMER="${CUSTOMER}"
export ENVIRONMENT="${ENVIRONMENT}"
export CLOUD_PROVIDER="${CLOUD_PROVIDER}"
export CLOUD_PROVIDERS="${CLOUD_PROVIDERS}"
export INTERNAL_DNS_ID="${INTERNAL_DNS_ID}"
export INTERNAL_DNS_NAME="${INTERNAL_DNS_NAME}"
export PRODUCT_NAME="${PRODUCT_NAME}"
export TENANT_ID="${TENANT_ID}"
export CLIENT_ID="${CLIENT_ID}"
export CLIENT_SECRET="${CLIENT_SECRET}"

. /opt/AIL/tools/utils.sh

(create_banner "${PRODUCT_NAME}"
 create_banner "@ ${REGION_ALIAS}" 
   echo
   echo "                   Built by AccessIndentified Infrastructure Automation"
   echo
   echo "                   AMI Build Version: ${BUILD_VERSION}"
   echo
   echo "              Server: ${PRODUCT_NAME}  Region: ${REGION}  Cluster: "
   echo
   echo "                    Deployed at $(date)"
) >> /etc/motd

bash /opt/AIL/install/ail_base.sh "${CUSTOMER}" "${ENVIRONMENT}" "${PRODUCT_NAME}"
echo "Base OS Setup complete"

bash /opt/AIL/install/control.sh

rm /opt/AIL/install/ail_base.sh
