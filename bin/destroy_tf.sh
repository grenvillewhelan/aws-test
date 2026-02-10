#!/bin/bash
#
# Script:       destroy_tf.sh
#
# Usage:        destroy_tf.sh <terraform-config-directory>
#
# Author:       Grenville Whelan, Access Identified Ltd
#
# Description:  
#
# See Also:     create_tf.sh
#

# Global variables
#

TLD="/Users/grenvillewhelan/AccessIdentified/BT"
COMMON_ROUTINES="${TLD}/bin/common_routines.sh"
TFVAR_DIR=${TLD}/tfvars.d                      # Location of .tfvars file to use
TFVAR_GEN="environment-customer.tfvars"        # Name of template tfvars file

cd ${TLD}

which tofu > /dev/null 2>&1

if [ $? -eq 0 ]; then
   TF_PROG="tofu"
else
   TF_PROG="terraform"
fi

TF_PROG="terraform"

#
# MAIN
#

if [ $# -ne 1 ]
then
   echo "usage: $0 <deployment-directory>"
   exit 1
fi

TF_DIR=$1

if [ ! -d ${TF_DIR} ]; then
   echo "Warning: cannot open ${TF_DIR}, exiting."
   exit 1
fi

customer_name=${TF_DIR%%-*}

if [ -f ${TF_DIR}/.terraform/environment ]; then
   environment_name=$(cat ${TF_DIR}/.terraform/environment 2> /dev/null)
else
   environment_name=$(echo $1 | awk -F\/ '{print $(NF-1)}' | awk -F- '{print $2}')
fi

TFVARS=${environment_name}-${customer_name}.tfvars
TFVARS_JSON=$(cat ${TF_DIR}/${TFVARS} | hcl2json)
CLOUD_PLATFORM=$(jq -n "${TFVARS_JSON}" | \
                 jq -r '.cloud_provider' 2> /dev/null)

cloud_providers=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.cloud_providers')

if [ -f "${COMMON_ROUTINES}" ]; then
   . "${COMMON_ROUTINES}"
else
   echo "$0: Warning cannot open ${COMMON_ROUTINES}, exiting."
   exit 1
fi

cloud_providers=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.cloud_providers')
DEBUG=${TF_DIR}/"deployment.log"
dns_suffix=$(get_deployment_parameter dns_suffix)
number_regions=$(jq -n "${TFVARS_JSON}" | \
                 jq -r '.manifest["'${CLOUD_PLATFORM}'"] | keys' 2> /dev/null | \
                 wc -l | awk '{print $1-2}')

echo
yellow_echo "//////////////////////////////////////////////////////////////"
yellow_echo "//                                                          //"
yellow_echo "//   ACCESS IDENTIFIED TERRAFORM CLOUD AUTOMATION WRAPPER   //"
yellow_echo "//                                                          //"
yellow_echo "//                    DEPLOYMENT DESTROYER                  //"
yellow_echo "//                                                          //"
yellow_echo "//////////////////////////////////////////////////////////////"
echo

chk_dir ${TF_DIR}

echo -n "Gathering configuration information .. "

PROFILE=${customer_name}_${environment_name}
region=$(get_deployment_parameter cloud_region)
AWS_ARGS="--region ${region} --profile ${PROFILE}"

lockfile=$(get_deployment_parameter terraform_state_locking)
state_storage=$(get_storage_backend)

#if [ "${DEFAULT_STATE_DEFAULT_STATE_STORAGE}" == "${state_storage:0:${#DEFAULT_STATE_DEFAULT_STATE_STORAGE}}" ]; then
#   state_storage=""
#fi

account_owner=$(get_deployment_parameter account_owner | \
                jq -r '.["'${environment_name}'"]' 2> /dev/null)

if [ -f ${TF_DIR}/${TFVARS} ]
then
   echo "done."
   echo

   exit_on_no "Destroy ${TF_PROG} setup for customer \"${customer_name}\" at \"${environment_name}\"?" 0

   writelog "destroy_deployment started for ${customer_name} at ${environment_name} in ${region}"
   
   # Empty buckets prior to teardown - note that subsequent updates to buckets in deployment may cause
   # teardown error anyway (e.g. pfadmin backup every 5 minute may kick in after our manual empty and
   # before terraform destroy below ..

   product_list=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.products | keys | .[]' 2> /dev/null)

   for product in ${product_list}
   do
      region_number=0

      while [ ${region_number} -lt ${number_regions} ]; do

         region_alias=$(jq -n "${TFVARS_JSON}" | \
                        jq -r '.manifest["'${CLOUD_PLATFORM}'"]['${region_number}'].region_alias' 2> /dev/null)
         installed=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest["'${CLOUD_PLATFORM}'"]['${region_number}'].products["'${product}'"]["'${environment_name}'"]' 2> /dev/null)
         if [ ${installed} -gt 0 ]; then
            empty_storage ${product} ${region_alias}
         fi

         ((region_number+=1))
      done
   done

   set_deployment_status "stop"

   if [ -z "${product_list}" ]; then
      echo "No deployment to destroy"
   else
      echo
      echo -n "Destroying deployment .. "
   fi
   
   logorno "(cd ${TF_DIR}; ${TF_PROG} destroy -var-file=${TFVARS} -auto-approve)"
   estat=$?

   if [ ${estat} -ne 0 ]; then
      echo failed.
      red_echo "Warning: [${TF_PROG} destroy -var-file=${TFVARS}] exited with ${estat}, exiting."

      while [ ${estat} -ne 0 ]
      do
         echo
         return1_on_no "Attempt to re-run the [${TF_PROG} destroy]?"
         estat=$?

         if [ ${estat} -eq 0 ]; then
            echo
            echo -n "Attempting to re-run .. "
            logorno "(cd ${TF_DIR}; ${TF_PROG} destroy -var-file=${TFVARS} -auto-approve)"
            estat=$?
            if [ ${estat} -ne 0 ]; then
               echo failed.
               red_echo "Warning: [${TF_PROG} destroy -var-file=${TFVARS}] exited with ${estat}, exiting."
            fi
         else
            estat=0
         fi
      done
   fi

else
   echo
   echo "No ${TF_PROG} configuration to destroy"
fi

echo
exit_on_no "Remove remote backend state?" 0

echo
echo "Removing remote state configuration"

writelog "Removing remote state configuration"

remove_state_setup

echo
exit_on_no "Remove deployment directory?" 0
printf " - %-68s" "Removing deployment directory ${TF_DIR} "
writelog "destroy_deployment completed for ${customer_name} at ${environment_name} in ${region}"
rm -rf ${TF_DIR}
if [ $? -eq 0 ]; then
   echo "ok."
else
   echo "failed."
fi

echo
echo "Destroy completed."
