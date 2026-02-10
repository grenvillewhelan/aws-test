#!/bin/bash

. /opt/AIL/tools/utils.sh

CUSTOMER=$1
ENVIRONMENT=$2
SERVER_TYPE=$3

function nrblue_echo() {
   echo -en "\033[0m\033[34m\033[1m$* \033[0m"
}

function apply_local_hardening() {
   echo "$0: Applying final hardening at $(date)"

   # Harbian 2.17_sticky_bit_world_writable

   chgrp root /run/screen

   # Harbian 2.4_tmpfs_noexec - Finalise hardening by remounting tmp with "noexec"

   if [ -d ${AIL_TOOLS}/harbian-audit-* ]; then
      echo "Running harbian"
      cd ${AIL_TOOLS}/harbian-audit-*
      export $(grep LEVEL= bin/run_audit.sh)
      bin/hardening.sh --set-hardening-level ${LEVEL} >> /var/log/harbian.log 2>&1
      # We don't set noexec on /tmp as per 2.4 as this prevents the Kinesis agent from running
   fi

# Temporarily disable hosts.deny whilst testing multi-region
#
#      if [ -z "$(ip address | grep ${control_ip})" ]; then
#         sed -i 's/^#ALL/ALL/' /etc/hosts.deny
#      fi

   chmod 600 /etc/passwd- /etc/shadow- /etc/group- /etc/gshadow-

   # Harbian 5.4_disable_ctrl_alt_del.target

   if [ -f /lib/systemd/system/ctrl-alt-del.target ]; then
      rm /lib/systemd/system/ctrl-alt-del.target
   fi

   ln -s /dev/null /lib/systemd/system/ctrl-alt-del.target

   # Harbian 8.1.1.2_halt_when_audit

   echo "space_left_action = email" >> /etc/audit/auditd.conf

   # Harbian 8.1.1.3_keep_all_audit_logs

   sed -i "s/max_log_file_action = .*/max_log_file_action = keep_logs/" /etc/audit/auditd.conf

   # Harbian 8.1.1*

   ln -s /etc/audit /etc/audisp
   # Harbian 8.1.1.6_ensure_set_encrypt_for_audit_remote

#   echo "enable_krb5 = yes" >> /etc/audisp/audisp-remote.conf

   # Harbian 8.1.1.7_ensure_set_action_for_audit_storage_full

   sed -i "s/disk_full_action = .*/disk_full_action = syslog/" /etc/audisp/audisp-remote.conf

   # Harbian 8.1.1.8_ensure_set_action_for_net_fail

   sed -i "s/network_failure_action = .*/network_failure_action = syslog/" /etc/audisp/audisp-remote.conf

   # Harbian 8.1.16_record_sudo_usage

#   echo "-w /var/log/sudo.log -p wa -k sudoaction" >> /etc/audit/rules.d/audit.rules

   # Harbian 8.1.27_record_events_that_modify_conf_files

#   echo "-F path=/etc/audisp/audisp-remote.conf -F perm=wa -k config_file_change" >> /etc/audit/rules.d/audit.rules
#   echo "-a always,exit -F path=/etc/audisp/plugins.d/au-remote.conf -F perm=wa -k config_file_change" >> /etc/audit/rules.d/audit.rules
#   echo "-a always,exit -F path=/etc/audisp/audisp-remote.conf -F perm=wa -k config_file_change" >> /etc/audit/rules.d/audit.rules

   # Harbian 8.1.34_record_privileged_commands

#   echo "-a always,exit -F path=/usr/bin/dotlockfile -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged-passwd" >> /etc/audit/rules.d/audit.rules

   # Harbian 8.5_ensure_permissions_on_all_logfiles

   chmod g-w,o-rwx /var/log/* /var/log/*/*

   # Harbian 9.3.13_sshd_limit_access


# Following line commented out due to issues with Debian update on Oct-7-2023
#   echo "AllowUsers admin" >> /etc/ssh/sshd_config
   echo "AllowGroups admin ${CUSTOMER}-${ENVIRONMENT}-ssh-${SERVER_TYPE}" >> /etc/ssh/sshd_config
   echo "DenyUsers root" >> /etc/ssh/sshd_config
   echo "DenyGroups root" >> /etc/ssh/sshd_config

   # Harbian 10.1.6_remove_nopassword_su
#   sed -i 's/NOPASSWD:ALL/PASSWD:ALL/g' /etc/cloud/cloud.cfg
#   sed -i 's/NOPASSWD:ALL/PASSWD:ALL/g' /etc/cloud/cloud.cfg.d/01_debian_cloud.cfg
#   sed -i 's/NOPASSWD:ALL/PASSWD:ALL/g' /etc/sudoers.d/90-cloud-init-users

   # Harbian 13.7_check_user_dir_permissions

   echo "$0: Hardening complete at $(date)"
}

echo "$0: Script started at $(date)"
CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)
echo
echo -n "Customer: "
nrblue_echo "${CUSTOMER}"
echo -n " Environment: "
nrblue_echo "${ENVIRONMENT}"
echo -n "on "
nrblue_echo "${CLOUD_PLATFORM}"
echo
echo

host_name="$(echo ${instance_id} | sed 's/_/-/g')"
echo "Setting hostname to: ${host_name}"
hostname ${host_name}
echo "${host_name}" > /etc/hostname

net_inf=$(ip -j link |jq -r '.[].ifname' | grep -v lo | head -1)
net_ip=$(ip -4 address show ${net_inf}| grep "inet " | grep -v 127.0.0 | awk '{print $2}' | \
             awk -F/ '{printf $1}')

if [[ ${net_ip}  =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
   echo "$0: Adding /etc/hosts entry for IP address ${net_ip}"
   echo "${net_ip}	${instance_id}	${instance_id}.${region}.int.${ENVIRONMENT}.${CUSTOMER}.${DNS_SUFFIX}" >> /etc/hosts
else
   echo "$0: not adding /etc/hosts entry, could not get IP address for local interface \"${net_inf}\""
fi



echo '
#!/bin/bash

echo -n "Logging into Azure: "
az login --service-principal \
         --username "'${CLIENT_ID}'" \
         --password "'${CLIENT_SECRET}'" \
         --tenant "'${TENANT_ID}'" | jq -r @@@@.[].cloudName@@@@' | sed "s/@@@@/'/g" > /opt/AIL/tools/azlogin.sh

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   bash /opt/AIL/tools/azlogin.sh
fi

update_name_tag "${SERVER_TYPE}-waiting"

echo "Updating sudoers for server type ${SERVER_TYPE} at $(date)"

echo "%${CUSTOMER}-${ENVIRONMENT}-ssh-${SERVER_TYPE}-sudo	ALL=(ALL:ALL) ALL" > /etc/sudoers.d/90-AID

echo
echo "Applying harbian local hardening at $(date)"

#if [ "${CLOUD_PLATFORM}" == "aws" ]; then
#   apply_local_hardening
#fi

wait_for_deployment_go ${SERVER_TYPE}

update_name_tag "${SERVER_TYPE}-deploying"
echo "$0: Script completed at $(date)"
