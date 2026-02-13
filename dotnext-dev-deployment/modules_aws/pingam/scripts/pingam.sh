#!/bin/bash

export CUSTOMER="${CUSTOMER}"
export ENVIRONMENT="${ENVIRONMENT}"
export PRODUCT="${PRODUCT}"
export BUILD_VERSION="${BUILD_VERSION}"
export MODULE_VERSION="${MODULE_VERSION}"
export REGION="${REGION}"
export REGION_ALIAS="${REGION_ALIAS}"
export NUMBER_OF_SERVERS="${NUMBER_OF_SERVERS}"
export HEALTH_CHECK_GRACE_PERIOD="${HEALTH_CHECK_GRACE_PERIOD}"
export CLOUD_DNS="${CLOUD_DNS}"
export DNS_SUFFIX="${DNS_SUFFIX}"
export CLUSTER="${CLUSTER}"
export PRODUCT_NAME="${PRODUCT_NAME}"
export CLOUD_PROVIDER="${CLOUD_PROVIDER}"
export CLOUD_PROVIDERS="${CLOUD_PROVIDERS}"

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

set_asg_healthcheck EC2 "${HEALTH_CHECK_GRACE_PERIOD}"
bash /opt/AIL/install/ail_base.sh "${CUSTOMER}" "${ENVIRONMENT}" "pingam"

echo
rm /opt/AIL/install/ail_base.sh

echo "Installing PingAM at $(date)"

if [ ! -f "/opt/AIL/install/pingam.sh" ]; then
   echo "$0: Cannot locate /opt/AIL/install/pingam.sh script, cannot continue, exiting."
   exit 1
fi

echo "Running /opt/AIL/install/pingam.sh"
bash /opt/AIL/install/pingam.sh
echo "AIL Base OS Setup complete"

echo "$0: Script completed at $(date)"
