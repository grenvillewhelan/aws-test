#!/bin/bash

PINGAM_VERSION=$1
aws_storage_account=$2
export REGION=$3

JAVA_VERSION="java-17-amazon-corretto-jdk"
CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)
. /opt/AIL/tools/utils.sh

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   BLOB_STORAGE_ACCOUNT_NAME="ailsoftware"
   BLOB_RESOURCE_GROUP_NAME="AIL-resource-group"
   BLOB_CONTAINER_NAME="ping"

   bash /opt/AIL/tools/azlogin.sh

   BLOB_ACCOUNT_KEY=$(az storage account keys list \
                    --resource-group ${BLOB_RESOURCE_GROUP_NAME} \
                    --account-name ${BLOB_STORAGE_ACCOUNT_NAME} \
                    --query '[0].value' -o tsv)

fi

echo 

echo
echo "========================================"
echo "Installing ${JAVA_VERSION}"

echo "Running wget to install corretto.key"
wget -O- https://apt.corretto.aws/corretto.key 2> /dev/null| apt-key add - > /dev/null 2>&1

echo "deb https://apt.corretto.aws stable main" > /etc/apt/sources.list.d/corretto.list

echo "Running apt-get update"
apt-get update

echo "Installing ${JAVA_VERSION}"
DEBIAN_FRONTEND=noninteractive apt-get install -y ${JAVA_VERSION}

if [ $? -ne 0 ]; then
   echo "WARNING: Failed to install Java, exiting"
   exit 1
fi

echo "${JAVA_VERSION} Installed"
echo "==============================================="


echo 
echo "========================================"
echo "Installing PingAM ${PINGAM_VERSION} at $(date)"


retVal=1

while [ ${retVal} -ne 0 ]
do
   DEBIAN_FRONTEND=noninteractive apt-get download sysstat > /dev/null 2>&1
   retVal=$?

   if [ ${retVal} -ne 0 ]; then
      echo " -  Waiting for apt-get to return with return non-zero status, currently ${retVal}"
      sleep 5
   fi
done

DEBIAN_FRONTEND=noninteractive apt-get install -y sysstat dstat gdb ruby

# --system
#adduser --disabled-password --quiet --gecos "" --group --system "${PD_USERNAME}" --home /home/${PD_USERNAME}

echo "${PD_USERNAME} soft nofile 65535" >> /etc/security/limits.conf
echo "${PD_USERNAME} hard nofile 65535" >> /etc/security/limits.conf
echo "${PD_USERNAME} soft nproc 65535" >> /etc/security/limits.conf
echo "${PD_USERNAME} hard nproc 65535" >> /etc/security/limits.conf

echo "
# Up Arrow history completion
bind '\"\e[A\": history-search-backward'
bind '\"\e[B\": history-search-forward'
" >> /home/${PD_USERNAME}/.bashrc


if [ ! -d /opt/AM-${PINGAM_VERSION} ]; then
   echo "Downloading AM-${PINGAM_VERSION}.zip at $(date)"

   mkdir -p /opt
   cd /opt

   retVal=1

   while [ ${retVal} -ne 0 ]
   do               
      if [ "${CLOUD_PLATFORM}" == "aws" ]; then
         get_stored_file "${aws_storage_account}" "AM-${PINGAM_VERSION}.zip" "${AIL_INSTALL}/"
         retVal=$?
      fi

      if [ "${CLOUD_PLATFORM}" == "azure" ]; then

         get_stored_file "${BLOB_CONTAINER_NAME}" "AM-${PINGAM_VERSION}.zip" \
                         "${AIL_INSTALL}/AM-${PINGAM_VERSION}.zip" \
                         "${BLOB_STORAGE_ACCOUNT_NAME}" "${BLOB_RESOURCE_GROUP_NAME}"
         retVal=$?
      fi

      if [ ${retVal} -ne 0 ]; then
         echo " - Waiting for ${CLOUD_PLATFORM} storage \"${aws_storage_account}/AM-${PINGAM_VERSION}.zip\" to return with non-zero status, currently ${retVal}"
         sleep 5
      fi
   done

   unzip -q "/opt/AIL/install/AM-${PINGAM_VERSION}.zip" \
    -x *.exe *.dll *.bat  



#   rm -f "/opt/AIL/install/AM-${PINGAM_VERSION}.zip"
else
   echo "$0: Not downloading AM-${PINGAM_VERSION}, already installed"
fi

# Set NUM_USER_PROCESSES to max available on running system if less than ping hardcoded 16383

max_available_proc=$(ulimit -u)


echo "Installed PingAM at $(date)"
echo "========================================"
echo ""
echo ""
