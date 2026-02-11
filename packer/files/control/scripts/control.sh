#!/bin/bash

. /opt/AIL/tools/utils.sh

export cloud_providers=$(jq -n ${CLOUD_PROVIDERS} | jq -r '. | join(" ")')

update_name_tag "${PRODUCT_NAME}-deploying"

echo "$0: Starting at $(date)"
         
if [ ! -f "${AIL_TOOLS}/utils.sh" ]; then
   echo "$0: Cannot locate ${AIL_TOOLS}/utils.sh script, cannot continue, exiting."
   exit 1
fi 
   
. ${AIL_TOOLS}/utils.sh

net_inf=$(ip -j link |jq -r '.[].ifname' | grep -v lo | head -1)
net_ip=$(ip -4 address show ${net_inf} | \
         grep "inet " | \
         grep -v 127.0.0 | \
         awk '{print $2}' | \
         awk -F/ '{printf $1}')

for cloud_provider in ${cloud_providers}
do
   if [ "${cloud_provider}" != "${CLOUD_PROVIDER}" ]; 
   then
      if [ "${cloud_provider}" == "azure" ]; then
         bash /opt/AIL/tools/azlogin.sh
      fi

      echo "Adding ${cloud_provider} DNS entry for ${net_ip} in ${PRODUCT_NAME}.${REGION_ALIAS}} at $(date)"

      CLOUD_PLATFORM=${cloud_provider} create_dns_a_record "${PRODUCT_NAME}.${REGION_ALIAS}" "${net_ip}" "int.${ENVIRONMENT}.${CUSTOMER}" "${INTERNAL_DNS_ID}"
   fi
done

update_name_tag "${PRODUCT_NAME}-running"
