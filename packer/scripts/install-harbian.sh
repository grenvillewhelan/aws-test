#!/bin/bash
#
# Script:       install-harbian.sh
#
# Usage:        install-harbian.sh 
#
# Author:       Grenville Whelan
#
# Description:  This script install, configures and runs Harbian (Debian Hardening) auditing
#               software in ${HARB_DIR} during packer AMI build. It initialises Harbian, 
#               performs an initial audit (in ${AUDIR_DIR}/audit0.log), performs a ${LEVEL}
#               hardening run, finalises the hardening and then performs a further audit
#               (in ${AUDIT_DIR}/audit1.log). Finally, it "installs" the script in 
#               ${HARB_DIR}/bin/run_audit.sh
#
#               This script may be used further once systems are running with no arguments
#               to just run a further audit (indexed by ${INST_FILE} and stored in ${AUDIT_DIR}
#
# See Also:     Harbian - individual audit checks are prefixed with numbers and can be located
#               in ${HARB_DIR}/bin/hardening/

HARBIAN_VERSION=$1
INSTALL_DIR="/opt/AIL"
HARB_FILE="${INSTALL_DIR}/install/harbian-audit-${HARBIAN_VERSION}.tar.gz"
HARB_DIR=${INSTALL_DIR}/harbian-audit-${HARBIAN_VERSION}
AUDIT_DIR=${HARB_DIR}/audits
INST_FILE=${AUDIT_DIR}/.audits
LOGFILE="/var/log/harbian.log"
LEVEL=5
ROOT_PWD=""
ADMIN_PWD=""

if [ -n "$2" ]; then
   TAG_VERSION=$2
else
   TAG_VERSION="unknown"
fi

(cd ${INSTALL_DIR}; ln -s harbian-audit-${HARBIAN_VERSION} harbian-audit)

# Hardening tasks not covered by Harbian to run manually

function apply_local_fixes()
{
   # Harbian 12.10_find_suid_files

   for x_file in /usr/bin/mount \
                 /usr/bin/umount \
                 /usr/lib/dbus-1.0/dbus-daemon-launch-helper /usr/sbin/exim4 \
                 /usr/bin/write.ul \
                 /usr/lib/aarch64-linux-gnu/utempter/utempter \
                 /usr/sbin/unix_chkpwd 
   do
      if [ -f ${x_file} ]; then
         chmod 755 ${x_file}
      fi
   done

   # Harbian 8.5_ensure_permissions_on

   chmod 640 /var/log/btmp \
             /var/log/apt/*.log \
             /var/log/lastlog \
             /var/log/wtmp

   # Harbian 13.7_check_user_dir_perm
   chmod o-rx /home/admin
}

function input_for_final()
{
   #
   # Harbian final command requires input:
   #
   #  Want to set new password for admin?    Y
   #  New password:                          <password>
   #  Retype new password:                   <password>
   #  Want to set new password for root?     Y
   #  New password:                          <password>
   #  Retype new password:                   <password>
   #  Run AIDE now?                          Y
   #  Overwrite existing AIDE?               Y

   echo y
   echo ${ADMIN_PWD}
   echo ${ADMIN_PWD}
   echo y
   echo ${ROOT_PWD}
   echo ${ROOT_PWD}
   echo y
   echo y
}

function create_motd() {               

   echo 
   echo "    Base AMI Version: ${TAG_VERSION} built and hardened at $(date)"
   echo
}

. /opt/AIL/tools/utils.sh

if [ ! -f ${INST_FILE} ]
then
   audit_number=1

   # Hardening processes clears out /tmp, so need to preserve current contents and
   # restore when harbian completes (later below)

   (cd /tmp; mv ssh-* /opt/; tar cf /opt/tmp.tar .)

   echo
   echo "******************************************"
   echo "**                                      **"
   echo "** INSTALLING HARBIAN AND HARDENING O/S **"
   echo "**                                      **"
   echo "******************************************"
   echo

   cd ${INSTALL_DIR}

   echo "$0: Installing HARBIAN"

   # Harbian uses bc (calculator)
   apt-get -y install bc > /dev/null 2>&1

   if [ ! -f ${HARB_FILE} ]; then
      echo "$0: cannot locate harbian-audit software \"${HARB_FILE}\", exiting"
      exit 1
   fi

   tar zxf ${HARB_FILE} 2> /dev/null
   rm -f ${HARB_FILE}
   cd ${HARB_DIR}
   cp etc/default.cfg /etc/default/cis-hardening
   sed -i "s#CIS_ROOT_DIR=.*#CIS_ROOT_DIR='$(pwd)'#" /etc/default/cis-hardening

   echo "$0: Initialising HARBIAN"
   bin/hardening.sh --init > ${LOGFILE} 2>&1

   mkdir -p ${AUDIT_DIR}
   echo "$0: Running initial HARBIAN audit"
   bin/hardening.sh --audit-all >> ${AUDIT_DIR}/audit0.log 2>&1
   echo
   tail -7 ${AUDIT_DIR}/audit0.log
   echo

   echo "$0: Applying HARBIAN audit level ${LEVEL}"
   bin/hardening.sh --set-hardening-level ${LEVEL} >> ${LOGFILE} 2>&1

   # For the following checks, replace "/run/shm" with "/dev/shm" for this Debian release

   for ignore_fix in 2.14_run_shm_nodev.sh \
                     2.15_run_shm_nosuid.sh \
                     2.16_run_shm_noexec.sh
   do
      sed -i "s#/run/shm#/dev/shm#" bin/hardening/${ignore_fix}
   done

   # Hardening components to be disabled:
   #  - Need to ensure /tmp is not mounted "noexec" otherwise next stage of packer fails
   #    This is re-applied in ail_base.sh
   #  - CLAMAV causing pf-admin to crash (oom-killer) - to be investigated
   #  - CSS-794 - skipping 5.2_disable_avahi_server.cfg due to hanging issue it causes when running install-harbian.sh in docker, see jira ticket for details

   for ignore_fix in 2.4_tmp_noexec.cfg \
                     6.17_ensure_virul_scan_server_is_enabled.cfg \
                     6.18_ensure_virusscan_program_update_is_enabled.cfg
   do
      sed -i "s/status=enabled/status=disabled/" etc/conf.d/${ignore_fix}
   done

   bin/hardening.sh --apply >> ${LOGFILE} 2>&1

   # Re-enable ssh during packer completion; ail_base.sh reapplies later

   sed -i 's/^ALL/#ALL/' /etc/hosts.deny

   echo "$0: Finalising HARBIAN"
   input_for_final | bin/hardening.sh --final >> ${LOGFILE} 2>&1

   # Restore stored /tmp contents
   (cd /tmp; tar xfp /opt/tmp.tar; mv /opt/ssh-* .; rm -f /opt/tmp.tar)

   apply_local_fixes

   echo "$0: Running final HARBIAN audit"
   bin/hardening.sh --audit-all >> ${AUDIT_DIR}/audit1.log 2>&1
   echo 1 > ${INST_FILE}
   echo
   tail -7 ${AUDIT_DIR}/audit1.log

   mv ${AIL_INSTALL}/install-harbian.sh ${HARB_DIR}/bin/run_audit.sh
   chmod +x ${HARB_DIR}/bin/run_audit.sh
   create_motd > /etc/motd
   echo "$0: Finished applying HARBIAN audit"
   echo
else
   audit_number=$(cat ${INST_FILE})
   ((audit_number+=1))
   cd ${HARB_DIR}
   echo -n "$0: Running audit .."
   bin/hardening.sh --audit-all > ${AUDIT_DIR}/audit${audit_number}.log
   echo done
   echo
   echo "$0: Audit saved in ${AUDIT_DIR}/audit${audit_number}.log"
   echo
fi

echo ${audit_number} > ${INST_FILE}
