#!/bin/bash
#
# Script:       create_tf.sh
#
# Usage:        create_tf.sh [-c] [-r <region> ] <customer-name> <environment>
#
# Author:       Grenville Whelan, Access Identified Limited
#
# Description:  
#
# See Also:     destroy_deployment.sh  recover_deployment.sh
#
#

function get_cloud_providers() {

   cloud_providers=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest | keys | .[]')

   for name in ${cloud_providers}
   do
      reg=$(jq -n "${TFVARS_JSON}" | \
            jq -r '.manifest["'${name}'"] | length')

      x=0
      p=0
      while [ ${x} -lt ${reg} ]; do
         ((p+=$(jq -n "${TFVARS_JSON}" | \
                jq -r '.manifest["'${name}'"]['${x}'].products | .[] | .["'${environment_name}'"]' | \
                awk '{tot+=$1}END{print tot}')))
         ((x+=1))
      done
   
      if [ ${p} -gt 0 ]; then
         echo -n "${name} "
      fi
   done
   echo
}

function get_manifest() {

cat ${TEMP_TFVARS1} | awk 'BEGIN{man=0;b=0}{
      if ($1=="manifest")
         man=1;

      if (index($0, "{"))
         ++b
      if (man ==1 && b == 0)
         man=0

      if (man == 1 && b > 0)
         print $0

      if (index($0, "}"))
         --b

   }'
}

function get_strip_regions() {

   manifest_json=$(get_manifest | hcl2json)

   for name in aws azure
   do
      reg=$(jq -n "${manifest_json}" | \
            jq -r '.manifest["'${name}'"] | length')

      x=0
      while [ ${x} -lt ${reg} ]; do
         p=$(jq -n "${manifest_json}" | \
           jq -r '.manifest["'${name}'"]['${x}'].products | .[] | .["'${environment_name}'"]' | \
           awk '{tot+=$1}END{print tot}')

         if [ ${p} -eq 0 ]; then
            echo ${name}:$(expr $x + 1)
         fi
         ((x+=1))
      done
   done
}

function strip_manifest_regions() {

   cloud_provider=$1
   region=$2

   awk 'BEGIN{man=0;b=0}{
      if ($1=="manifest")
         man=1;

      if (index($0, "{"))
         ++b

      if (man ==1 && b == 0)
         man=0

      if (man == 1 && b == 1) {
         if ($1 == manifest_cloud)
            r=1
         else {
            r=0
            e=0
         }
      }

      if (r == 1) {
         if (index($1, "{") && b == 2) 
            ++e
      }

      if (man == 1 && b > 0 && e != manifest_region)
         print $0

      if (index($0, "}"))
         --b

   }' manifest_cloud="\"${cloud_provider}\"" manifest_region=${region}
}

function tfvars_before_manifest() {

   cat ${TFVAR_DIR}/${TFVAR_GEN} | awk 'BEGIN{man=0;b=0}{
      if ($1=="manifest")
         man=1;

      if (index($0, "{"))
         ++b

      if (man ==1 && b == 0)
         man=2

      if (man == 0)
         print $0

      if (index($0, "}"))
         --b
   }'
}

function tfvars_after_manifest() {

   cat ${TFVAR_DIR}/${TFVAR_GEN} | awk 'BEGIN{man=0;b=0}{
      if ($1=="manifest")
         man=1;

      if (index($0, "{"))
         ++b

      if (man ==1 && b == 0)
         man=2

      if (man == 2)
         print $0

      if (index($0, "}"))
         --b
   }'
}

function process_manifest() {
   TEMP_TFVARS2="/tmp/.tfvars2$$"

   cat ${TFVAR_DIR}/${TFVAR_GEN} > ${TEMP_TFVARS1}

   if [ -z "$(get_strip_regions)" ]; then
      get_manifest
      return
   fi

   while [ "$(get_strip_regions)" != "" ]
   do
      entry=$(get_strip_regions | head -1)
      cloud=$(echo $entry | awk -F: '{print $1}')
      region=$(echo $entry | awk -F: '{print $2}')
      cat ${TEMP_TFVARS1} | strip_manifest_regions ${cloud} ${region} > ${TEMP_TFVARS2}
      cat ${TEMP_TFVARS2} > ${TEMP_TFVARS1}
   done

   cat ${TEMP_TFVARS1}
   rm -f ${TEMP_TFVARS1} ${TEMP_TFVARS2}
}

function strip_manifest() {
   tfvars_before_manifest
   process_manifest
   tfvars_after_manifest
}

USAGE="Usage: $(basename $0) [-c] [-r <region>] <cloud-provider> <customer-name> <environment>"

while getopts 'cr:' opt; do
  case "$opt" in
    c)
      CREATE_TEMPLATE=1
      ;;

    r)
      INTERNAL_STATE=0
      REMOTE_REGION=${OPTARG}
      ;;

    ?|h)
      echo ${USAGE}
      exit 1
      ;;
  esac
done

shift "$(($OPTIND -1))"

customer_name=$(echo $1 | tr '[:upper:]' '[:lower:]')
environment_name=$2

# Global variables

TLD="/Users/grenvillewhelan/AccessIdentified/BT"
TOOLING_DIR=${TLD}/tooling
COMMON_ROUTINES="${TLD}/bin/common_routines.sh"
TEMP_TFVARS1="/tmp/.tfvars1$$"
TFVAR_DIR=${TLD}/tfvars.d                      # Location of .tfvars file to use
TFVAR_GEN="environment-customer.tfvars"        # Name of template tfvars file
TFVARS_JSON=$(strip_manifest| hcl2json 2> /dev/null)
if [ $? -ne 0 ]; then
   echo "Warning: HCL error in \"${TFVAR_GEN}\""
   exit 1
fi

if [ $# -eq 2 ]; then
   PACKER_PROFILE=${customer_name}_${environment_name}
   cloud_providers=$(get_cloud_providers)
else
   echo ${USAGE}
   exit 1
fi

primary_aws_region=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest["aws"][0].region_name')
export AWS_REGION=${primary_aws_region}

primary_azure_region=$(jq -n "${TFVARS_JSON}" | \
                       jq -r '.manifest["azure"][0].region_name')

CLOUD_PLATFORM=$(echo ${cloud_providers} | awk '{print $1}')
cd ${TLD}

if [ -f "${COMMON_ROUTINES}" ]; then
   . "${COMMON_ROUTINES}"
else
   echo "$0: Warning cannot open ${COMMON_ROUTINES}, exiting."
   exit 1
fi

which tofu > /dev/null 2>&1

if [ $? -eq 0 ]; then
   TF_PROG="tofu"
else
   TF_PROG="terraform"
fi

TF_PROG="terraform"

ROUTE53_PROVIDER=$(grep "^route53_provider" ${TFVAR_DIR}/${TFVAR_GEN} | awk -F= '{print $NF}' | awk '{print $1}')

if [ -z "${ROUTE53_PROVIDER}" ]; then
   ROUTE53_PROVIDER="route53"
fi

# Location of software distributions in S3

#
# MAIN
#

check_env_variables

CREATE_TEMPLATE=0
INTERNAL_STATE=1

primary_region=$(jq -n "${TFVARS_JSON}" | \
                 jq -r '.manifest["'${CLOUD_PLATFORM}'"][0].region_name')
primary_region_alias=$(jq -n "${TFVARS_JSON}" | \
                       jq -r '.manifest["'${CLOUD_PLATFORM}'"][0].region_alias')
dns_suffix=$(jq -n "${TFVARS_JSON}" | \
             jq -r '.dns_suffix')

TFVARS=${environment_name}-${customer_name}.tfvars

if [ "$(jq -n "${TFVARS_JSON}" | \
        jq -r '.test_mode')" == "true" ]; then
   TEST_MODE=1
else
   TEST_MODE=0
fi

#PREFIX=$(echo ${customer_name}-${environment_name}-${primary_region} | sed 's/_/-/g')
PREFIX=$(echo ${customer_name}-${environment_name} | sed 's/_/-/g')

if [ ${INTERNAL_STATE} -eq 0 ]; then
   remote_state="remote_state"
else
   remote_state=$(echo ${PREFIX}"-remote_state" | sed 's/-/_/g')
fi

# working terraform deployment directory for this customer deployment

TF_DIR=${PREFIX}"-deployment"
DEBUG=${TF_DIR}/"deployment.log"

dns_suffix=$(jq -n "${TFVARS_JSON}" | \
             jq -r '.dns_suffix["'${CLOUD_PLATFORM}'"]')
dns_suffix_length=${#dns_suffix}
customer_name_length=${#customer_name}
total_name_length=$(expr ${dns_suffix_length} + ${customer_name_length})

#if [ ${total_name_length} -gt 28 ]; then
#   red_echo "Warning, customer name cannot exceed $(expr ${total_name_length} - ${dns_suffix_length}) characters."
#   exit 1
#fi

if [ -d ${TF_DIR} ]; then
   red_echo "$0: Warning, deployment directory \"${TF_DIR}\" already exists, exiting."
   exit 1
fi

check_region ${primary_region}

if [ $? -ne 0 ]; then
   red_echo "$0: Warning, invalid region \"${primary_region}\", exiting"
   exit_prog 1
fi

echo
yellow_echo "//////////////////////////////////////////////////////////////"
yellow_echo "//                                                          //"
yellow_echo "//   ACCESS IDENTIFIED TERRAFORM CLOUD AUTOMATION WRAPPER   //"
yellow_echo "//                                                          //"
yellow_echo "//                     DEPLOYMENT CREATOR                   //"
yellow_echo "//                                                          //"
yellow_echo "//////////////////////////////////////////////////////////////"
echo
display_logo

for check in "${platform_package_checks}" \
             "chk_dir ${TFVAR_DIR}" \
             "chk_dir ${TEMPLATE_DIR}" \
	     "chk_file ${TFVAR_DIR}/${TFVAR_GEN}" \
	     "is_package_installed packer" \
	     "is_package_installed ${TF_PROG}" \
	     "is_package_installed git" \
	     "is_package_installed jq" \
	     "is_package_installed hcl2json"
do
   ${check}

   if [ $? -ne 0 ]; then
      exit 1
   fi
done

custom_ami=""

echo
echo "Cloud Providers                                                  .. ${cloud_providers}"
echo "Terraform State Cloud Provider                                   .. ${tf_state_cloud_provider}"

for cloud_provider in ${cloud_providers}
do
   echo "Primary deployment region:                                       .. ${cloud_provider} $(get_regions ${cloud_provider} primary)"
   echo -n "Secondary deployment region(s):                                  .. "
   get_regions ${cloud_provider} secondary | paste -sd,  -
   echo
done

if [ ${CREATE_TEMPLATE} -ne 0 ]; then
   echo "Deployment:                                                      .. creating terraform code only"
else
   echo "Deployment:                                                      .. running full deploy"
fi

if [ ${INTERNAL_STATE} -eq 1 ]; then
   echo "Remote state storage and dynamodb table:                         .. deployment-based"
else
   echo "Remote state storage and dynamodb table:                         .. AccessIdentified repository"
fi

for cloud_provider in ${cloud_providers}
do
   echo
   nrblue_echo "Deploying the following products in ${cloud_provider}:"
   echo
   echo
   region_number=0

   number_regions=$(jq -n "${TFVARS_JSON}" | \
                    jq -r '.manifest["'${cloud_provider}'"] | keys' 2> /dev/null | \
                    wc -l | awk '{print $1-2}')
   
   while [ ${region_number} -lt ${number_regions} ]
   do
      dep_region=$(jq -n "${TFVARS_JSON}" | \
                   jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_name')
      dep_alias=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_alias')
      yellow_echo "${dep_region} (${dep_alias}):"
      echo
   
      for product in $(jq -n "${TFVARS_JSON}" | \
                       jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].products | keys | .[]')
      do
         installs=$(jq -n "${TFVARS_JSON}" | \
                    jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].products["'${product}'"]["'${environment_name}'"]')
         cluster=$(jq -n "${TFVARS_JSON}" | \
                   jq -r '.products["'${product}'"].cluster')
         module=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.products["'${product}'"].module')
   
         if [ -n "${cluster}" ]; then
            cluster="(Cluster \"${cluster}\")"
         fi
   
         if [ ${installs} -gt 0 ]; then
            printf " - %-24s (%-16s) x %d  %s\n" ${product} ${module} ${installs} "${cluster}"
         fi
      done
   
      echo
      ((region_number+=1))
   done
done

aws_access_key_id=$(get_aws_profile_value "packer" aws_access_key_id)
aws_secret_access_key=$(get_aws_profile_value "packer" aws_secret_access_key)

verify_credentials

for cloud_provider in ${cloud_providers}
do
   region_number=0
   dependency_errors=0

   for region in $(get_regions ${cloud_provider} all)
   do
      printf "%-66s" "Checking manifest for product dependencies in ${cloud_provider} ${region}:"
      check_product_dependencies ${region_number}
      region_dependency_errors=$?
      ((dependency_errors+=${region_dependency_errors}))
      ((region_number+=1))
   
      if [ ${region_dependency_errors} -gt 0 ]; then
         echo
         echo "   Identified ${region_dependency_errors} product dependency error(s)"
         echo
      else
         echo "  Ok."
      fi
   done
done

if [ ${dependency_errors} -gt 0 ]; then
   red_echo "Warning, identified ${dependency_errors} product dependency error(s), exiting."
   echo
   exit
fi

deregister_amis=""

for cloud_provider in ${cloud_providers}
do
   if [ ${CREATE_TEMPLATE} -eq 0 ]; then
  
      number_cloud_regions=$(jq -n "${TFVARS_JSON}" | \
                             jq -r '.manifest["'${cloud_provider}'"] | keys' | \
                             wc -l | awk '{print $1-2}')

      region_number=0
      while [ ${region_number} -lt ${number_cloud_regions} ]; do
         check_region=$(jq -n "${TFVARS_JSON}" | \
                        jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_name')
         chk_ami ${cloud_provider} ${region_number} ${environment_name} ${check_region}
         retVal=$?

         if [ ${retVal} -eq 2 ]; then
            echo
            return1_on_no "All AMIs available at ${check_region}, but would you like to refresh them anyway?"
      
            if [ $? -eq 0 ]; then
               return1_on_no "Deregister existing AMIs at ${check_region} first?"
      
               if [ $? -eq 0 ]; then
                  deregister_amis=${check_region}" "${deregister_amis}
               fi
            fi 
         else
            if [ ${retVal} -eq 1 ]; then
               deregister_amis=${check_region}" "${deregister_amis}
            fi
         fi
         ((region_number+=1))

         if [ -n "$(echo ${deregister_amis} | grep ${check_region})" ]; then
            yellow_echo " - AMI rebuild required"
         else
            yellow_echo " - No AMI rebuild required"
         fi
      done
   fi
done

if [ ${CREATE_TEMPLATE} -eq 0 ]; then
   echo
   return1_on_no "Put deployed servers into \"wait\" mode until deployment is complete?"
      
   if [ $? -eq 0 ]; then
      deployment_status="wait"
   else
      deployment_status="go"
   fi
fi

echo
echo "Created deployment directory ${TF_DIR}"
   
if [ "${DEBUG}" != "" ]; then
   echo "Sending debug output to ${DEBUG}"
fi
   
mkdir -p ${TF_DIR}
writelog "create_deployment started for ${customer_name} in ${primary_region}"

if [ ${INTERNAL_STATE} -eq 0 ]; then
   state_storage=${DEFAULT_STATE_STORAGE}-${REMOTE_REGION}
   lockfile=${DEFAULT_STATE_LOCKFILE}
else
   state_storage=${PREFIX}"-tfstatefile"
   lockfile=${PREFIX}"-lockfile"
fi

create_tfvars > ${TF_DIR}/${TFVARS}

echo
echo "Using environment parameters:"
echo
echo "   Customer                          : "${customer_name}
echo "   DNS Suffix                        : "${dns_suffix}
echo "   Tag versions                      : "${TAG_VERSION}
echo "   Environment                       : "${environment_name}
echo "   TF State Cloud Provider           : "${tf_state_cloud_provider}
echo

exit_on_no "Ready to start deployment ${TF_DIR}?" 0


if [ ${CREATE_TEMPLATE} -eq 0 ]; then
   echo
   prepare_state_setup
fi
   
if [ -n "${deregister_amis}" ]; then
 
   for cloud_provider in ${cloud_providers}
   do
      for ami_region in ${deregister_amis}
      do
         cloud_check=$(jq -n "${TFVARS_JSON}" | \
                       jq -r '.manifest["'${cloud_provider}'"] | .[].region_name' | \
                       awk '{for (i=1; i<=NF; ++i) if ($i == reg) print $i}' reg=${ami_region})

         if [ "${cloud_check}" == "${ami_region}" ]; then
            echo
            echo "Deregistering ${cloud_provider} AMIs at ${ami_region}"

            for curr_ami in $(get_installed_amis ${cloud_provider})
            do 

               if [ "${cloud_provider}" == "aws" ]; then
                  curr_ami_id=$(echo ${curr_ami} | awk -F: '{print $1}')
                  curr_ami_name=$(echo ${curr_ami} | awk -F: '{print $2}')
               fi

               if [ "${cloud_provider}" == "azure" ]; then
                  curr_ami_id=$(echo ${curr_ami} | awk -F: '{print $2}')
                  curr_ami_name=$(echo ${curr_ami} | awk -F- '{printf("%s-%s-%s",$5, $6,$7)}')
               fi

               return1_on_no "Deregister ${ami_region} ${curr_ami_id} (${curr_ami_name})?"
          
               if [ $? -eq 0 ]; then
   
                  writelog "Deregistering ${ami_region} ${curr_ami_id} (${curr_ami_name})"
                  echo -n " - deregistering ${curr_ami_id} (${curr_ami_name}) .. "
                  deregister_ami ${ami_region} ${curr_ami_id}
                  rebuild_amis=${ami_region}" "${rebuild_amis}
               fi
            done
            echo
         fi
      done
   done
fi

echo
echo "Rechecking AMIs"

rebuild_amis=""

for cloud_provider in ${cloud_providers}
do
   if [ ${CREATE_TEMPLATE} -eq 0 ]; then
  
      number_cloud_regions=$(jq -n "${TFVARS_JSON}" | \
                             jq -r '.manifest["'${cloud_provider}'"] | keys' | \
                             wc -l | awk '{print $1-2}')
      region_number=0

      while [ ${region_number} -lt ${number_cloud_regions} ]; do
         check_region=$(jq -n "${TFVARS_JSON}" | \
                        jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_name')
         chk_ami ${cloud_provider} ${region_number} ${environment_name} ${check_region}
         retVal=$?
 
         if [ ${retVal} -eq 1 ]; then
            yellow_echo " - AMI rebuild required"
            echo
            return1_on_no "Need to run AMI builder (base-images) at ${check_region}, continue?"
      
            if [ $? -eq 1 ]; then
               echo "Ok, exiting."
               exit 1
            fi

            rebuild_amis=${check_region}" "${rebuild_amis}
         else
            yellow_echo " - no AMI rebuilds required at ${check_region}"
         fi
         ((region_number+=1))
      done
   fi
done

for cloud_provider in ${cloud_providers}
do
   echo
   printf "   %-54s %s\n" "Primary ${cloud_provider} Region/Location : " $(get_regions ${cloud_provider} primary)
   printf  "   %-54s %s\n" "Secondary ${cloud_provider} Region(s)/Location(s) : " $(get_regions ${cloud_provider} secondary)
done

echo
printf "   %-54s %s\n" "DynamoDB Table                    : " ${lockfile}
printf "   %-54s %s\n" "State Storage                     : " ${state_storage}
echo

if [ ${TEST_MODE} -eq 1 ]; then
   rm -f ${TF_DIR}/admin_access.pem
   create_pem
fi

if [ -n "${rebuild_amis}" ]; then

   echo
   for cloud_provider in ${cloud_providers}
   do
      build_this_provider=0
      p_region=$(get_regions ${cloud_provider} primary)
      other_regions=""
      includes_primary_region=0

      for reg in ${rebuild_amis}
      do
         ami_cloud=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest | map_values(select(.[].region_name == "'${reg}'")) | keys.[]')

         if [ "${ami_cloud}" == "${cloud_provider}" ]; then
            other_regions="${other_regions} ${reg}"
            ((build_this_provider+=1))

            if [ "${reg}" == "${p_region}" ]; then
               includes_primary_region=1
            fi
         fi
      done
   
      if [ ${includes_primary_region} -eq 0 ]; then
         p_region=$(echo ${other_regions} | awk '{print $1}')
      fi

#      if [ "${ami_cloud}" != "aws" ]; then
#         t_regions=$(echo ${other_regions} | \
#             awk '{for (i=1; i<=NF; ++i) if ($i != PRIM) printf("%s ", $i)}' PRIM=${p_region})
#         other_regions=${t_regions}
#      fi
   
      ami_build_regions=$(echo ${other_regions} | \
                awk 'BEGIN{printf("[")}{for (i=1; i<=NF; ++i) printf("\\\"%s\\\",",$i)}END{printf("]\n")}' | \
                sed 's/,]$/]/g')
   
      if [ ${build_this_provider} -gt 0 ]; then
         label=$(echo "Rebuilding ${cloud_provider} AMIs at ${p_region} and ${ami_build_regions} " | \
                 sed 's/\\//g')
         printf "%-60s" "${label}"
         writelog "Starting new AMI build: primary ${p_region}, other regions ${ami_build_regions}"
         packer_args="${p_region} ${ami_build_regions}"

         cloud_ami=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest | map_values(select(.[].region_name == "'${p_region}'")) | keys.[]')

         if [ "${cloud_ami}" == "${cloud_provider}" ]; then
               logorno "build_amis ${p_region} ${ami_build_regions}"
               retVal=$?
      
            if [ ${retVal} -ne 0 ]; then
               echo "warning."
               red_echo "Warning: [build_amis ${p_region} ${ami_build_regions} failed with ${retVal}, exiting."
            else
               echo "ok."
            fi
         fi
         build_this_provider=0
      fi
   done
fi

echo
echo -n "hit [return] to continue with deployment build .. "
read waitforit

echo
echo -n "Preparing full ${TF_PROG} configuration .. "

strip_manifest >> ${TF_DIR}/${TFVARS}
temp_file="/tmp/.tfmainsed$$"

for cloud_provider in ${cloud_providers}
do
   mkdir ${TF_DIR}/modules_${cloud_provider}

   for product in $(jq -n "${TFVARS_JSON}" | \
                    jq -r .'products | keys | .[]')
   do
      chk=$(jq -n "${TFVARS_JSON}" | \
            jq -r '.manifest["'${cloud_provider}'"] | .[].products["'${product}'"]["'${environment_name}'"]' | \
            awk '{tot+=$1}END{print tot}')

      if [ ${chk} -gt 0 ]; then
         mod=$(jq -n "${TFVARS_JSON}" | \
               jq -r '.products["'${product}'"].module')
         (cd ${TEMPLATE_DIR}/modules_${cloud_provider}; tar cf - ${mod}) | \
         (cd ${TF_DIR}/modules_${cloud_provider}; tar xfp -)

         for main in $(cd ${TF_DIR}/modules_${cloud_provider}; ls)
         do
            main_file=$(ls ${TF_DIR}/modules_${cloud_provider}/${main}/main*tf 2> /dev/null)

            if [ -n "${main_file}" ]; then
               cp ${main_file} ${temp_file}
               cat ${temp_file} | \
                  sed 's/!!TF_AWS_VERSION!!/'${TF_AWS_VERSION}'/g' | \
                  sed 's/!!TF_AZURE_VERSION!!/'${TF_AZURE_VERSION}'/g' > ${main_file}
               rm -f ${temp_file}
            fi
         done
      fi
   done
done

create_main ${cloud_providers} |
        sed 's/!!STATE_STORAGE!!/'${state_storage}'/g' | \
        sed 's/!!SUBSCRIPTION_ID!!/'${ARM_SUBSCRIPTION_ID}'/g' | \
        sed 's/!!CUSTOMER!!/'${customer_name}'/g' | \
        sed 's/!!ENVIRONMENT!!/'${environment_name}'/g' | \
        sed 's/!!PRIMARY_AWS_REGION!!/'${primary_aws_region}'/g' | \
        sed 's/!!PRIMARY_AZURE_REGION!!/'${primary_azure_region}'/g' | \
        sed 's/!!REMOTE_STATE!!/'${remote_state}'/g' | \
        sed 's/!!STORAGE_ACCOUNT_NAME!!/'${STORAGE_ACCOUNT_NAME}'/g' | \
        sed 's/!!RESOURCE_GROUP_NAME!!/'${RESOURCE_GROUP_NAME}'/g' | \
        sed 's/!!TF_AWS_VERSION!!/'${TF_AWS_VERSION}'/g' | \
        sed 's/!!TF_AZURE_VERSION!!/'${TF_AZURE_VERSION}'/g' | \
        sed 's/!!LOCKFILE!!/'${lockfile}'/g' > ${TF_DIR}/main.tf

for template in $(cd ${TEMPLATE_DIR}; ls variables.template)
do
   if [ -f ${TEMPLATE_DIR}/${template} ]; then
      tf_file=$(echo ${template} | sed 's/_/-/g' | sed 's/.template$/\.tf/')

      cat ${TEMPLATE_DIR}/${template} | \
         sed 's/!!CUSTOMER!!/'${customer_name}'/g' | \
         sed 's/!!ENVIRONMENT!!/'${environment_name}'/g' | \
         sed 's/!!REGION!!/'${primary_aws_region}'/g' | \
         sed 's/!!CLOUD!!/'${CLOUD_PLATFORM}'/g' | \
         sed 's/!!STATE_LOCKFILE!!/'${lockfile}'/g' | \
         sed 's/!!REMOTE_STATE!!/'${remote_state}'/g' | \
         sed 's/!!REGION_ALIAS!!/'${primary_region_alias}'/g' | \
         sed 's/!!STORAGE_ACCOUNT_NAME!!/'${STORAGE_ACCOUNT_NAME}'/g' | \
         sed 's/!!RESOURCE_GROUP_NAME!!/'${RESOURCE_GROUP_NAME}'/g' > ${TF_DIR}/${tf_file}
   fi
done

for cloud_provider in ${cloud_providers}
do
   region_number=0
   number_regions=$(jq -n "${TFVARS_JSON}" | \
                    jq -r '.manifest["'${cloud_provider}'"] | keys' 2> /dev/null | \
                    wc -l | awk '{print $1-2}')
   
   while [ ${region_number} -lt ${number_regions} ]; do
      region_name=$(jq -n "${TFVARS_JSON}" | \
                    jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_name')
      region_alias=$(jq -n "${TFVARS_JSON}" | \
                     jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].region_alias')

      if [ -f ${TEMPLATE_DIR}/secrets_${cloud_provider}.template ]; then
         cat ${TEMPLATE_DIR}/secrets_${cloud_provider}.template | \
            sed 's/!!REGION_NAME!!/'${region_name}'/g' | \
            sed 's/!!CUSTOMER!!/'${customer_name}'/g' | \
            sed 's/!!ENVIRONMENT!!/'${environment_name}'/g' | \
            sed 's/!!REGION_ALIAS!!/'${region_alias}'/g' > ${TF_DIR}/secrets-${region_alias}-${cloud_provider}.tf
      fi
   
      for product in $(jq -n "${TFVARS_JSON}" | \
                       jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].products | keys | .[]')
      do
         prod_installed=$(jq -n "${TFVARS_JSON}" | \
                          jq -r '.manifest["'${cloud_provider}'"]['${region_number}'].products["'${product}'"]["'${environment_name}'"]')
         module=$(jq -n "${TFVARS_JSON}" | \
                  jq -r '.products["'${product}'"].module')
         cluster=$(jq -n "${TFVARS_JSON}" | \
                   jq -r '.products["'${product}'"].cluster')
   
         if [ ${prod_installed} -gt 0 ]; then
            cat ${TEMPLATE_DIR}/products_${cloud_provider}.template | \
                awk 'BEGIN{x=0}{if (index($0, MOD)) x=1
                      if (x == 1) print $0
                      if (substr($1,1,1) == "}") {if (x == 1) printf("}\n"); x=0}
                      }' MOD='module "'${module}'_' | \
                      sed 's/module "'${module}'_/module "'${product}'_/' | \
                      sed 's/!!CLOUD!!/'${cloud_provider}'/g' | \
                      sed 's/!!PRODUCT!!/'${product}'/g' | \
                      sed 's/!!CLUSTER!!/'${cluster}'/g'
            echo
         fi
      done | sed 's/!!REGION_ALIAS!!/'${region_alias}'/g' | \
             sed 's/!!TAG_VERSION!!/'${TAG_VERSION}'/g' | \
             sed 's/!!REGION_NUMBER!!/'${region_number}'/g' >> ${TF_DIR}/products-${region_alias}-${cloud_provider}.tf
      add_region_provider ${cloud_provider} ${region_alias} ${region_name} >> ${TF_DIR}/main.tf
   
      ((region_number+=1))
   done
   add_other_providers ${cloud_provider} >> ${TF_DIR}/main.tf
done

create_locals >> ${TF_DIR}/locals.tf

if [ ${TEST_MODE} -eq 1 ]; then
   for cloud_provider in ${cloud_providers}
   do 
      cat ${TEMPLATE_DIR}/private_${cloud_provider}.template | \
         sed 's#^}#\
\
   provisioner "local-exec" {\
      command = "./create_pem.sh ${var.test_mode}" \
\
      environment = {\
         SECKEY = tls_private_key.global_ssh_key.private_key_pem \
      }\
   }\
}#g' > ${TF_DIR}/private.tf
   done
else
   if [ -f ${TEMPLATE_DIR}/private_${cloud_provider}.template ]; then
      cp ${TEMPLATE_DIR}/private_${cloud_provider}.template ${TF_DIR}/private.tf
   fi
fi

echo -n "Initialising ${TF_PROG}  .. "
logorno "(cd ${TF_DIR}; ${TF_PROG} init -upgrade -var-file=${TFVARS})"
estat=$?

if [ ${estat} -ne 0 ]; then
   red_echo "failed."
   red_echo "Warning: [${TF_PROG} apply -var-file=${TFVARS} -auto-approve] failed with ${estat}, exiting."

   while [ ${estat} -ne 0 ]
   do
      echo
      exit_on_no "Attempt to re-run the [${TF_PROG} init]?" 0
      echo
      echo -n "Attempting re-run .. "
      logorno "(cd ${TF_DIR}; ${TF_PROG} init -upgrade -var-file=${TFVARS})"
      estat=$?
   done
fi

echo done

logorno "(cd ${TF_DIR}; ${TF_PROG} workspace new ${environment_name})"
estat=$?

if [ ${estat} -ne 0 ]; then
   red_echo "Warning: [${TF_PROG} workspace new ${environment_name}] failed with ${estat}, exiting."
   exit_prog 1
fi

echo
echo -n "hit [return] to continue with deployment apply .. "
read waitforit

echo
echo -n "Applying full ${TF_PROG} build .. "

logorno "(cd ${TF_DIR}; ${TF_PROG} apply -var-file=${TFVARS} -auto-approve)"
estat=$?

if [ ${estat} -ne 0 ]; then
   red_echo "failed."
   red_echo "Warning: [${TF_PROG} apply -var-file=${TFVARS} -auto-approve] failed with ${estat}, exiting."

   while [ ${estat} -ne 0 ]
   do
      echo
      exit_on_no "Attempt to re-run the [${TF_PROG} apply]?" 0
      echo
      echo -n "Attempting re-run .. "
      logorno "(cd ${TF_DIR}; ${TF_PROG} apply -var-file=${TFVARS} -auto-approve)"
      estat=$?
   done
fi

echo done

echo
echo -n "Hit [return] to set deployment to go: "
read key
echo

yellow_echo "Deployment complete, setting deployment status to \"go\""

set_deployment_status "go"

writelog "create_deployment completed for ${customer_name} in ${primary_region}" 

if [ ${TEST_MODE} -eq 1 ]; then
   echo
   yellow_echo "The following info is only provided in TEST mode, to remove this for production use"
   yellow_echo "set <test_mode> to false in tfvars.d/environment-customer.tfvars"
   echo

   for cloud_provider in ${cloud_providers}
   do
      if [ "${cloud_provider}" == "aws" ]; then
         admin_user="ubuntu"
      fi

      if [ "${cloud_provider}" == "azure" ]; then
         admin_user="adminuser"
      fi

      for alt_region in $(get_regions ${cloud_provider} all)
      do
         control_ip=$(get_control_ip ${alt_region})
   
         if [ -n "${control_ip}" ]; then
            alt_alias=$(get_region_alias ${alt_region})
            echo
            echo "${alt_region} Control public IP address is: ${control_ip}, accessible with command:"
            echo
            yellow_echo "ssh -i ${TF_DIR}/admin_access.pem ${admin_user}@${control_ip}"
            echo "ssh -i ${TF_DIR}/admin_access.pem ${admin_user}@${control_ip}" > ${TF_DIR}/bas_ssh.sh
            echo
            echo "Copy ${alt_region} (${alt_alias}) secret key to control with:"
            echo
            yellow_echo "scp -i ${TF_DIR}/admin_access.pem ${TF_DIR}/admin_access.pem  ${admin_user}@${control_ip}:/home/${admin_user}"
            echo
         fi
      done
   done

   echo "SSL Tunnel for RDP:"
   echo ssh -L 33389:10.10.10.213:3389 -i dotnext-dev-deployment/admin_access.pem ubuntu@3.249.167.43 

#   echo "hosts entries:"
#   echo
#   create_hosts > ${TF_DIR}/hosts
#   cat ${TF_DIR}/hosts
   echo

   rm -f ${TF_DIR}/create_pem.sh
fi
 
echo "Build complete."
exit 0
