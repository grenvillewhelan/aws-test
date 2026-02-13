#!/bin/bash
#
# Script:      create-volumes.sh
#
# Description: This script creates and mounts volumes based on give argument that
#              is provided by the automated terraform deployment.
#
#              It uses the tag "Drives" configured during build with a list of comma
#              separated list of volumes in the format:
# 
#                    device:volume:mount_point
#
#                   For example "/dev/sdg:logs:/data/logs,/dev/sdk:test:/data/test"
#
#              In the event that one of the given devices is not ready (first sfdisk
#              command fails), it tries up to a further MAX_TRIES times with a 5 second
#              wait.

MAX_TRIES=120
CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)
AWS_PROFILE="packer"

function runit() {

   echo " - $1: << running [$*] >>"

   # Prettify output of given command (for clearer logging purposes)

   (((($* 2>&1; echo $? >&3 ) | awk '{printf(" - %s: %s\n",comm,$0)}' comm=$1 >&4) 3>&1) | \
      (read xs; exit $xs)) 4>&1

   if [ $? -eq 0 ]; then
      echo " - $1: << completed >>"
   else
      echo " - $1: << failed with $? return status >>"
   fi
}

function get_vol() {

   drive=$(echo $1 | sed 's#/dev/##')
   tries=0

   while [ ${tries} -lt ${MAX_TRIES} ]
   do
      if [ ! -h /sys/block/${drive} ]; then
         tries=$(expr ${tries} + 1)
         echo " - Waiting for /sys/block/${drive} to be available .. (${tries} of ${MAX_TRIES} tries)"
         sleep 10
      else
         tries=${MAX_TRIES}
      fi
   done

   vol=$(udevadm info -q symlink --path=/sys/block/${drive} | \
         awk '{for (i=1; i<=NF; ++i)  if (index($i, "disk/by-id/nvme-Amazon_Elastic_Block_Store")) print $i}' | \
         awk -F_ '{print $5}' | head -1)

   echo ${vol}:/dev/${drive}
}

function get_lun() {

   drive=$(echo $1 | sed 's#/dev/##')
   tries=0

   while [ ${tries} -lt ${MAX_TRIES} ]
   do
      if [ ! -h /sys/block/${drive} ]; then
         tries=$(expr ${tries} + 1)
         echo " - Waiting for /sys/block/${drive} to be available .. (${tries} of ${MAX_TRIES} tries)"
         sleep 10
      else
         tries=${MAX_TRIES}
      fi
   done

   lun=$(udevadm info -q symlink --path=/sys/block/${drive} | awk '{for (i=1; i<=NF; ++i)  if (index($i, "disk/azure/")) print $i}' | awk -F/ '{print $NF}' | sed 's/lun//g')

   echo ${lun}:/dev/${drive}
}

function process_drives() {

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      TEMP="/tmp/.create-drives-$$"

      for drive in $(echo $* | jq -r '.[].diskName')
      do
         get_lun ${drive}
      done > ${TEMP}

      for lun in $(echo $* | jq -r '.[].lun')
      do
         diskName=$(awk -F: '{if ($1==LUN) print $2}' LUN=${lun} ${TEMP})
         volumeName=$(echo $* | jq -r '.[] | select(IN(.lun; '${lun}')) | .volumeName')
         mountPoint=$(echo $* | jq -r '.[] | select(IN(.lun; '${lun}')) | .mountPoint')
         echo -n "${diskName}:${volumeName}:${mountPoint}",
      done | sed 's/,$//'
      echo

      rm -f ${TEMP}
      return
   fi

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      DRIVE_MAPPINGS=""

      while [ -z "${DRIVE_MAPPINGS}" ]
      do
         not_ready=0

         AWS_DRIVES=$(aws ${AWS_ARGS} ec2 describe-volumes \
                            --region ${REGION}  \
                            --filters "Name=attachment.instance-id,Values=${instance_id}" \
                            --query "Volumes[*].Attachments[*].[VolumeId, Device]" \
                            --output text 2> /dev/null)

         for diskName in $(echo $* | jq -r '.[].awsName')
         do
            if [ -z "$(echo ${AWS_DRIVES} | grep ${diskName})" ]; then
               ((not_ready+=1))
            fi
         done

         if [ ${not_ready} -eq 0 ]; then
            DRIVE_MAPPINGS=$(aws ${AWS_ARGS} ec2 describe-volumes \
                            --region ${REGION}  \
                            --filters "Name=attachment.instance-id,Values=${instance_id}" \
                            --query "Volumes[*].Attachments[*].[VolumeId, Device]" \
                            --output text 2> /dev/null | \
                            awk '{printf("%s:%s\n", $2, $1)}')
         fi

         if [ -z "${DRIVE_MAPPINGS}" ]; then
            sleep 10
         fi
      done

      for diskName in $(echo $* | jq -r '.[].awsName')
      do
         nvmediskName=$(echo $* | jq -r '.[] | select(IN(.awsName; "'${diskName}'")) | .diskName')
         actualvolumeId=$(get_vol ${nvmediskName} | awk -F: '{print $1}')

         for vol in ${DRIVE_MAPPINGS}
         do
            volumeId=$(echo ${vol} | awk -F: '{print $2}' | sed 's/-//g')
            attacheddiskName=$(echo ${vol} | awk -F: '{print $1}' | sed 's/-//g')

            if [ "${actualvolumeId}" == "${volumeId}" ]; then
               volumeName=$(echo $* | jq -r '.[] | select(IN(.awsName; "'${attacheddiskName}'")) | .volumeName')
               mountPoint=$(echo $* | jq -r '.[] | select(IN(.awsName; "'${attacheddiskName}'")) | .mountPoint')
               newdiskName=${nvmediskName}
            fi
         done

         echo -n "${newdiskName}:${volumeName}:${mountPoint}",
      done | sed 's/,$//'
      echo
   fi
}

echo "$0: Started at $(date)"

. /opt/AIL/tools/utils.sh

echo "$0: getting ${CLOUD_PLATFORM} region ${REGION} drive_list at $(date)"

if [ -n "$(echo $* | grep '^\[{')" ]; then
   drive_list=$(process_drives $*)
   if [ $? -ne 0 ]; then
      echo "$0: cannot process given drive-list:\n"
      cat $* | awk '{printf(" << %s >>\n",$0)}'
      exit 1
   fi
else
   drive_list=$*
fi

if [ -z "${drive_list}" ]
then
   echo "Cannot identify volumes, exiting"
   exit 1
fi

number_entries=$(echo ${drive_list} | awk -F, '{print NF}')

if [ -z "${number_entries}" ]
then
   echo "No volumes given, exiting"
   exit 1
else
   echo "got drive_list: ${drive_list} at $(date)"
fi

echo "========================================"
echo " $0: Creating ${number_entries} volume(s)"

for entry in $(echo ${drive_list} | awk -F, '{for (x=1; x<=NF; ++x) print $x}')
do
   drive=$(echo ${entry} | awk -F: '{print $1}')
   drive_tag=$(echo  ${entry} | awk -F: '{print $2}')
   mount_point=$(echo  ${entry} | awk -F: '{print $3}')

   echo
   echo " Creating volume \"${drive_tag}\" using drive \"${drive}\" on mount point \"${mount_point}\" at $(date)"
   echo
   tries=0
   
   # If /dev/drive_tag/drive_tag already exists, fs already exists from fs snapshot
   
   if [ ! -b /dev/${drive_tag}/${drive_tag} ]; then
      while [ ${tries} -lt ${MAX_TRIES} ]
      do
         if [ -b ${drive} ]; then
            tries=${MAX_TRIES}
            echo ',,8e;' | runit sfdisk ${drive}
            runit wipefs --all ${drive}
            runit pvcreate -y ${drive}
            runit vgcreate -y ${drive_tag} ${drive}
            runit lvcreate -y -n ${drive_tag} -l 100%FREE ${drive_tag}
            runit mkfs.ext4 /dev/${drive_tag}/${drive_tag}
         else
            tries=$(expr ${tries} + 1)
            echo " - Waiting for ${drive} to be available .. (${tries} of ${MAX_TRIES} tries)"
            sleep 5
         fi
      done
   fi
   
   runit mkdir -p ${mount_point}
   echo "/dev/${drive_tag}/${drive_tag}  ${mount_point}  ext4  defaults,noatime,nofail 0 2" >> /etc/fstab
   runit mount ${mount_point}
done

echo
echo " $0: Completed at $(date)"
echo "========================================"

