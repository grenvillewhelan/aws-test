#!/bin/bash
export CLOUD_PLATFORM=$1
export REGION=$2
export CLIENT_ID="$3"
export CLIENT_SECRET="$4"
export TENANT_ID="$5"
export AWS_ACCESS_KEY_ID=$6
export AWS_SECRET_ACCESS_KEY=$7

echo ${CLOUD_PLATFORM} > /opt/AIL/.cloud_platform

AIL_S3_REPO="s3://ail-${REGION}/software"

echo "========================================"
echo "Install folder"

ls -lR /opt/AIL/install


################################################################
## Updating and installing core software
################################################################

echo "========================================"
echo "Updating"

#sed -i 's/http:\/\//https:\/\//g' /etc/apt/sources.list

retVal=1

while [ ${retVal} -ne 0 ]
do
   sudo apt-get upgrade
   sudo apt-get update

   DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade

   DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg2 vim \
                                                     haveged \
                                                     nslcd \
                                                     lvm2 \
                                                     unzip \
                                                     jq \
                                                     ca-certificates \
                                                     net-tools \
                                                     figlet \
                                                     dnsutils

   retVal=$?

   if [ ${retVal} -ne 0 ]; then
      echo "apt-get install errored, sleeping for 10 and retry"
      sleep 10
   fi
done

DEBIAN_FRONTEND=noninteractive apt-get purge -y nano exim4

if [ $? -ne 0 ]; then
   echo "apt-get purge failed, exiting."
   exit 1
fi

echo "Installing Azure CLI"
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "Setting up AWS Credentials"

mkdir -p /root/.aws

echo '[packer]
aws_access_key_id     = '${AWS_ACCESS_KEY_ID}'
aws_secret_access_key = '${AWS_SECRET_ACCESS_KEY} | sed 's/"//g' > /root/.aws/credentials

echo
echo 'export AWS_PROFILE="packer"' >> /root/.bash_profile

echo '
#!/bin/bash

echo -n "Logging into Azure: "
az login --service-principal \
         --username '${CLIENT_ID}' \
         --password '${CLIENT_SECRET}' \
         --tenant '${TENANT_ID}' | jq -r @@@@.[].cloudName@@@@' | sed "s/@@@@/'/g" > /opt/AIL/tools/azlogin.sh

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   bash /opt/AIL/tools/azlogin.sh
   echo "azlogin returned $?"
fi

echo "Updated"
echo "========================================"
echo ""
echo ""

################################################################
## Updating and installing core software
################################################################

echo "========================================"
echo "Customise server"

sed -i 's/^preserve_hostname.*/preserve_hostname: true/g' /etc/cloud/cloud.cfg
sed -i '/^ - set_hostname/d' /etc/cloud/cloud.cfg
sed -i '/^ - update_hostname/d' /etc/cloud/cloud.cfg
sed -i '/^ - update_etc_hosts/d' /etc/cloud/cloud.cfg
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

echo ""
echo "========================================"
echo ""
echo ""

echo "Enabling mkhomedir"

DEBIAN_FRONTEND=noninteractive /usr/sbin/pam-auth-update --enable mkhomedir

echo "Enabled"
echo "========================================"
echo ""
echo ""

################################################################
## Install SSM Agent  [CSS-410]
################################################################

echo "========================================"

#if [ "${CLOUD_PLATFORM}" == "aws" ]; then

   echo "Installing AWS CLI"
   DEBIAN_FRONTEND=noninteractive apt-get install -y awscli
   echo

   echo "Installing SSM Agent for ${ARCH}"

   SSM_ARCH="amd64"

   if [ "${ARCH}" == "aarch64" ]; then
     SSM_ARCH="arm64"
   fi

   cd /tmp

   wget "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_${SSM_ARCH}/amazon-ssm-agent.deb" 2> /dev/null
   dpkg -i amazon-ssm-agent.deb 2> /dev/null

   echo "Installed"
   echo "========================================"
#fi
echo

#if [ "${CLOUD_PLATFORM}" == "aws" ]; then
#   echo "========================================"
#   echo "Retrieving Harbian version ${HARBIAN_VERSION} from ${AIL_S3_REPO}"
#
#   cd /opt/AIL/install
#   aws s3 cp --quiet ${AIL_S3_REPO}/harbian-audit-${HARBIAN_VERSION}.tar.gz .
#   retVal=$?
#   
#   if [ ${retVal} -ne 0 ]; then
#      echo "$0: Failed to retrieve Harbian agent, aws s3 returned ${retVal}"
#      exit 1
#   else
#      echo "Successfully retrieved Harbian"
#   fi
#
#   echo "Retrieved"
#   echo "========================================"
#fi

echo "set mouse-=a" >> /etc/vim/vimrc.local

echo "========================================"
echo "Disabled mouse in VIM"
echo "========================================"
