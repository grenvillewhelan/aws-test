#!/bin/bash
export CLOUD_PLATFORM=$1
export REGION=$2
export CLIENT_ID="$3"
export CLIENT_SECRET="$4"
export TENANT_ID="$5"
export AWS_ACCESS_KEY_ID=$6
export AWS_SECRET_ACCESS_KEY=$7

# Determine Architecture for SSM
ARCH=$(uname -m)

echo ${CLOUD_PLATFORM} > /opt/AIL/.cloud_platform
AIL_S3_REPO="s3://ail-${REGION}/software"

echo "========================================"
echo "Install folder"
ls -lR /opt/AIL/install

################################################################
## Updating and installing core software (RHEL 9 / DNF)
################################################################
echo "========================================"
echo "Updating"

cd /tmp
sudo sed -i 's/enabled=1/enabled=0/g' /etc/dnf/plugins/subscription-manager.conf
sudo curl -sSLo /tmp/epel-release-9.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

if [ $(stat -c%s "/tmp/epel-release-9.rpm") -gt 5000 ]; then
    sudo dnf install -y /tmp/epel-release-9.rpm
else
    echo "Download failed or file is too small. Check connectivity to mirrors."
    exit 1
fi

sudo chmod 644 /tmp/epel-release-9.rpm
sudo dnf install -y -q /tmp/epel-release-9.rpm
rm -f /tmp/epel-release-9.rpm

retVal=1
while [ ${retVal} -ne 0 ]
do
   sudo dnf clean all
   sudo dnf makecache
   sudo dnf upgrade -y

   # RHEL Package mappings:
   # nslcd -> nss-pam-ldapd
   # dnsutils -> bind-utils
   sudo dnf install -y gnupg2 vim \
                       haveged \
                       nss-pam-ldapd \
                       lvm2 \
                       unzip \
                       jq \
                       ca-certificates \
                       net-tools \
                       figlet \
                       bind-utils \
                       wget

   retVal=$?
   if [ ${retVal} -ne 0 ]; then
      echo "dnf install errored, sleeping for 10 and retry"
      sleep 10
   fi
done

# Remove nano and postfix (RHEL equivalent of exim4)
sudo dnf remove -y nano postfix


echo "Installing Azure CLI"
# 1. Import the specific GPG key for Microsoft packages
sudo rpm --import https://packages.microsoft.com

echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com" | sudo tee /etc/yum.repos.d/azure-cli.repo

# 3. Install it
sudo dnf install -y azure-cli

echo "Setting up AWS Credentials"
mkdir -p /root/.aws
echo '[packer]
aws_access_key_id     = '${AWS_ACCESS_KEY_ID}'
aws_secret_access_key = '${AWS_SECRET_ACCESS_KEY} | sed 's/"//g' > /root/.aws/credentials

echo 'export AWS_PROFILE="packer"' >> /root/.bash_profile

echo '
#!/bin/bash
echo -n "Logging into Azure: "
az login --service-principal \
         --username '${CLIENT_ID}' \
         --password '${CLIENT_SECRET}' \
         --tenant '${TENANT_ID}' | jq -r @@@@.[].cloudName@@@@' | sed "s/@@@@/'/g" > /opt/AIL/tools/azlogin.sh
chmod +x /opt/AIL/tools/azlogin.sh

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   bash /opt/AIL/tools/azlogin.sh
   echo "azlogin returned $?"
fi

################################################################
## Customise server
################################################################
echo "========================================"
echo "Customise server"

sed -i 's/^preserve_hostname.*/preserve_hostname: true/g' /etc/cloud/cloud.cfg
sed -i '/^ - set_hostname/d' /etc/cloud/cloud.cfg
sed -i '/^ - update_hostname/d' /etc/cloud/cloud.cfg
sed -i '/^ - update_etc_hosts/d' /etc/cloud/cloud.cfg
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# Enabling mkhomedir (RHEL way)
echo "Enabling mkhomedir"
authselect select minimal with-mkhomedir --force
systemctl enable --now oddjobd

################################################################
## Install SSM Agent (RHEL / RPM)
################################################################
echo "========================================"
echo "Installing AWS CLI"
sudo dnf install -y awscli

echo "Installing SSM Agent"
# Corrected URL construction
if [ "$ARCH" == "aarch64" ]; then 
    SSM_URL_ARCH="arm64"
else 
    SSM_URL_ARCH="amd64"
fi

sudo dnf install -y "https://s3.amazonaws.com{SSM_URL_ARCH}/amazon-ssm-agent.rpm"
sudo systemctl enable --now amazon-ssm-agent

echo "Installed & Configured"
echo "========================================"
