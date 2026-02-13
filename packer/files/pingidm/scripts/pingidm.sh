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
export LOC_DIR="/opt/openidm"

echo "$0: running pingidm.sh $*"

if [ ! -d "${LOC_DIR}" ]; then
  echo "$0: cannot locate ${LOC_DIR}"
fi

PD_USER="ubuntu"
chown -R "${PD_USER}:${PD_USER}" ${LOC_DIR}
echo "Running PingIDM setup"
echo

echo "${VERSION}" > /opt/openidm/.version
update_name_tag "${SERVER_NAME}-running"

echo "$0: Completed at $(date)"
