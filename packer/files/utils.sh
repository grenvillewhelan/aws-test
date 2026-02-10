#!/bin/bash

export AWS_ARGS="--profile packer --region ${REGION}"
export CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)
export AIL_INSTALL="/opt/AIL/install"
export AIL_TOOLS="/opt/AIL/tools"

function get_ssl_info() {
   host=$1
   port=$2

   if [ $# -ne 2 ]; then
      echo "usage: get_ssl_info host port"
      exit 1
   fi

   echo | openssl s_client -showcerts -servername $1 -connect $1:$2 2>/dev/null | openssl x509 -inform pem -noout -text

}

function check_required_envs() {

   for params_to_check in CUSTOMER \
                          ENVIRONMENT
   do
      cmd="echo \${$(eval echo ${params_to_check})}"
   
      if [ -z "$(eval ${cmd})" ]; then
         echo "$0: Warning - required parameter \"${params_to_check}\" has not been set"
      fi
   done
}

function pingport() {
      
   if [ $# -ne 2 ]; then
      echo "usage: pingport <ip-address> <port>"
      return 1
   fi
   
   $(echo >/dev/tcp/$1/$2) && echo Success
}

function wait_for_ssm() {
   ssm_region=$1
   param_name=$2

   value=$(get_ssm "${ssm_region}" "${param_name}" 2>&1)

   start_secs=$(date +'%s')

   while [ -z "${value}" ]
   do
      secs_now=$(date +'%s')
      echo "     waiting for \"${param_name}\" to be set ($(expr ${secs_now} - ${start_secs}) seconds)"
      sleep 10
      value=$(get_ssm "${ssm_region}" "${param_name}" 2>&1)
   done

   echo "\"${param_name}\" is set"
}

function create_new_password() {
  openssl rand -base64 48
}

function create_banner() {

   NAME=$1
   BLUE="\033[0m\033[34m\033[1m"
   COLOUR_OFF="\033[0m"
   screen_width=74
 
   which figlet > /dev/null 2>&1

   if [ $? -eq 0 ]; then
      longest_line=$(echo ${NAME} | figlet -f slant | awk -FQ 'BEGIN{x=0}{if(length($1)>x) x=length($1)}END{printf("%d\n", x)}')

      if [ ${longest_line} -gt ${screen_width} ]; then
         indent=0
      else
         indent=$(expr $(expr ${screen_width} - ${longest_line}) / 2)
      fi

      echo ${NAME} | figlet -f slant | \
           awk -FQ '{i=0;
                     while (i <= INDENT) {
                        printf(" ")
                        i = i+1;
                     }
           printf("        %s%s%s\n", BLUE, $1, OFF)}' BLUE=${BLUE} OFF=${COLOUR_OFF} INDENT=${indent}
   else
      echo
      length=$(echo ${NAME} | awk '{print length($1)}')

      if [ ${length} -gt ${screen_width} ]; then
         indent=0
      else
         indent=$(expr $(expr ${screen_width} - ${length}) / 2)
      fi

      echo ${NAME} | awk '{i=0;
                     while (i <= INDENT) {
                        printf(" ")
                        i = i+1;
                     }
                     printf("%s\n", $1) }' INDENT=${indent}
      echo
   fi
}

function wait_for_deployment_go() {

   server_type=$1
   check_required_envs
   deployment_status=$(get_ssm "${region}" "/"${CUSTOMER}"/"${ENVIRONMENT}"/deployment_status" 2>&1)

   if [ $? -ne 0 ]; then
      echo "$0: Cannot read deployment status from parameter store, continuing without waiting."
      return 1
   fi

   if [ "${deployment_status}" == "wait" ]; then

      if [ "${server_type}" == "pingfed_admin" \
        -o "${server_type}" == "pingfed_runtime" ]; then
         set_asg_healthcheck EC2 "${HEALTH_CHECK_GRACE_PERIOD}"
      fi
   fi
   start_secs=$(date +'%s')
   echo
   echo "Checking Deployment Status at $(date)"

   while [ "${deployment_status}" != "go" ]
   do
      sleep 10
      secs_now=$(date +'%s')
      echo "     waiting for Deployment Status to change to \"go\" ($(expr ${secs_now} - ${start_secs}) seconds)"

      deployment_status=$(get_ssm "${region}" "/"${CUSTOMER}"/"${ENVIRONMENT}"/deployment_status")
   done

   echo "Deployment Status set to \"${deployment_status}\" at $(date)"
}

function claim_leadership() {
  local PRIMARY_PARAMETER_STORE=$1
  local LEADER_PARAM=$2

  local time_now=$(date)
         
  put_ssm ${PRIMARY_PARAMETER_STORE} ${LEADER_PARAM} "${instance_id},${region},${time_now}" > /dev/null 2>&1
  return $?
}
   
function clear_leadership() {
  local PRIMARY_PARAMETER_STORE=$1
  local LEADER_PARAM=$2

  delete_ssm ${PRIMARY_PARAMETER_STORE} ${LEADER_PARAM}

  if [ $? -ne 0 ]; then
     echo "$0: failed to delete parameter \"${LEADER_PARAM}\""
  fi
}

#!/bin/bash

AWS_CLI_READ_TIMEOUT=5
AWS_CLI_CONNECT_TIMEOUT=5
FAIL_AFTER_ATTEMPTS=3

if [ "${CLOUD_PLATFORM}" == "aws" ]; then
   az=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
   region=${az%%?}
   instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
   dns_hostname=$(curl -s http://169.254.169.254/latest/meta-data/hostname)
   local_ipv4_address=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
fi

if [ "${CLOUD_PLATFORM}" == "azure" ]; then
   region=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/location?api-version=2017-08-01&format=text" 2> /dev/null)
   instance_id=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/name?api-version=2017-08-01&format=text" 2> /dev/null)
   resource_group=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/resourceGroupName?api-version=2017-08-01&format=text" 2> /dev/null)
   subscription_id=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/compute/subscriptionId?api-version=2017-08-01&format=text" 2> /dev/null)
fi

function set_asg_healthcheck() {

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      echo "set_asg_healthcheck not available for Azure"
      return 0
   fi

   health_check_type=$1
   grace_period=$2

   if [ $# -ne 2 ]; then
      echo "usage: set_asg_healthcheck <health-check-type> <health-check-grace-period>"
      echo "Setting with defaults EC2 and 300"
      health_check_type=EC2
      grace_period=300
   fi

   asg=$(get_my_autoscale_group ${region})

   if [ -z "${asg}" ]; then
      echo
      echo "Cannot determine autoscale group, cannot change health_check_type to \"${health_check_type}\""
   else
      existing_check_type=$(aws ${AWS_ARGS} autoscaling describe-auto-scaling-groups --region ${region} \
                                --auto-scaling-group-name ${asg} \
                                --query "AutoScalingGroups[].HealthCheckType" \
                                --output text)

      if [ $? -ne 0 ]; then
         echo "Cannot determine ASG ${asg} health_check_type, continuing without change."
         return 1
      fi

      if [ "${existing_check_type}" == "${health_check_type}" ]; then
         echo "ASG health_check_type already set to ${health_check_type}"
      else
         echo -n "Changing ASG ${asg} health_check_type to \"${health_check_type}\" .. "

         aws ${AWS_ARGS} autoscaling update-auto-scaling-group \
             --auto-scaling-group-name ${asg} \
             --health-check-grace-period ${grace_period} \
             --health-check-type ${health_check_type} \
             --region ${region} > /dev/null

         retVal=$?

         if [ ${retVal} -eq 0 ]; then
           echo "done."
         else
            echo "failed with ${retVal} return."
         fi
      fi
   fi
}

function get_my_autoscale_group() {

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      echo "get_my_autoscale_group not available for Azure"
      return 0
   fi

   if [ $# -ne 1 ]; then
      echo "usage: get_my_autoscale_group <region>"
      return 1
   fi
   
   local_region=$1
 
   aws ${AWS_ARGS} autoscaling describe-auto-scaling-instances --region ${local_region} \
            --query 'AutoScalingInstances[*].[InstanceId,AutoScalingGroupName]' --output text | \
            awk '{if ($1 == II) print $2}' II=${instance_id}
}

function update_name_tag() {
   NAME=$1

   if [ $# -eq 3 ]; then
      on_instance=${2}
      in_region=${3}
   else
      on_instance=${instance_id}
      in_region=${region}
   fi

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      aws ${AWS_ARGS} ec2 create-tags \
            --resources "${on_instance}" \
            --region "${in_region}" \
            --tags Key=Name,Value=${NAME} > /dev/null 2>&1
      retVal=$?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      resource_id="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CUSTOMER}-${ENVIRONMENT}-resource-group/providers/Microsoft.Compute/virtualMachines/${on_instance}"

      az tag update \
         --operation merge \
         --resource-id ${resource_id} \
         --tags Name="${NAME}" > /dev/null 2>&1

      retVal=$?
   fi

   return ${retVal}
}

function get_ssm_param_version() {
  PARAM=$1

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      echo "get_ssm_param_version not available for Azure"
      return 0
   fi

   if [ $# -eq 2 ]; then
      ssm_region=$2
   else
      ssm_region=${region}
   fi

   aws ${AWS_ARGS} ssm get-parameter \
         --cli-read-timeout ${AWS_CLI_READ_TIMEOUT} \
         --cli-connect-timeout ${AWS_CLI_CONNECT_TIMEOUT} \
         --output text \
         --region "${ssm_region}" \
         --name "${PARAM}" \
         --query 'Parameter.Version' 2> /dev/null

   return $?
}

function create_dns_a_record() {
   RECORD=$1
   IP=$2
   HOSTED_ZONE_NAME=$3
   HOSTED_ZONE_ID=$4
   BACKGROUND=$5

   if [ "${BACKGROUND}" != "yes" ]; then
      echo "Adding ${CLOUD_PLATFORM} DNS entry for ${IP} in ${RECORD}.${HOSTED_ZONE_NAME} at $(date)"

      if [ "${CLOUD_PLATFORM}" == "azure" ]; then

         az network private-dns record-set a show \
             --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group \
             --zone-name "${HOSTED_ZONE_NAME}" \
             --name "${RECORD}" > /dev/null 2>&1 > /dev/null 2>&1

         if [ $? -ne 0 ]; then
            echo "Azure DNS record-set \"${RECORD}\" does not exist, creating it"

            az network private-dns record-set a create \
                --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group \
                --zone-name "${HOSTED_ZONE_NAME}" \
                --name "${RECORD}" \
                --ttl 60 > /dev/null 2>&1

             if [ $? -eq 0 ]; then
                echo "Created Azure DNS record-set \"${RECORD}\" ok."
             else
                echo "Failed to create Azure DNS record-set \"${RECORD}\", continuing in background"
                create_dns_a_record $* "yes" &
                return
             fi
         fi

         az network private-dns record-set a update \
          --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group \
          --zone-name "${HOSTED_ZONE_NAME}" \
          --name "${RECORD}" \
          --add "a_records" "ipv4Address=${IP}" > /dev/null 2>&1

         if [ $? -ne 0 ]; then
            echo "Process to update \"${RECORD}\" in Azure DNS continuing in background"
            create_dns_a_record $* "yes" &
            return
         else
            echo "Azure DNS record \"${RECORD}\" successfully updated"
            return
         fi
      fi

      if [ "${CLOUD_PLATFORM}" == "aws" ]; then

         retVal=1
         start_secs=$(date +'%s')

         current_records=$(aws ${AWS_ARGS} route53 list-resource-record-sets \
             --hosted-zone-id "${HOSTED_ZONE_ID}" \
	     --query "ResourceRecordSets[?Name == '${RECORD}.${HOSTED_ZONE_NAME}.']" 2> /dev/null | \
	       jq -r '.[].ResourceRecords' | sed 's/\[//g' | sed 's/\]//g')

         if [ -z "${current_records}" ]; then
            new_records='{
    "Value": "'${IP}'"
}'
         else
            new_records='{
    "Value": "'${IP}'"
},
 '${current_records}
         fi

         aws ${AWS_ARGS} route53 change-resource-record-sets \
               --hosted-zone-id "${HOSTED_ZONE_ID}" \
               --change-batch file://<(cat << EOF
{
  "Comment": "Creating A record ${RECORD}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD}.${HOSTED_ZONE_NAME}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          ${new_records}
        ]
      }
    }
  ]
}
EOF
) > /dev/null 2>&1

         if [ $? -eq 0 ]; then
            echo "AWS DNS record \"${RECORD}\" successfully updated"
            return 0
         else
            echo "Process to update \"${RECORD}\" in AWS DNS continuing in background"
            create_dns_a_record $* "yes" &
         fi
      fi
   else
      if [ "${CLOUD_PLATFORM}" == "azure" ]; then

         retVal=1
         start_secs=$(date +'%s')

         while [ ${retVal} -ne 0 ]
         do
            az network private-dns record-set a update \
                --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group \
                --zone-name "${HOSTED_ZONE_NAME}" \
                --name "${RECORD}" \
                --add "a_records" "ipv4Address=${IP}" > /dev/null 2>&1
   
            retVal=$?
   
            if [ ${retVal} -ne 0 ]; then
               sleep 10 
               secs_now=$(date +'%s')
               echo "Waiting for Azure DNS record \"${RECORD}\" to accept update - ($(expr ${secs_now} - ${start_secs}) seconds)"
            fi
         done

         echo "Azure DNS record \"${RECORD}\" successfully updated"
         return 0
      fi

      if [ "${CLOUD_PLATFORM}" == "aws" ]; then

         retVal=1
         start_secs=$(date +'%s')

         while [ ${retVal} -ne 0 ]
         do
            sleep 10
            current_records=$(aws ${AWS_ARGS} route53 list-resource-record-sets \
                --hosted-zone-id "${HOSTED_ZONE_ID}" \
                --query "ResourceRecordSets[?Name == '${RECORD}.${HOSTED_ZONE_NAME}.']" 2> /dev/null | \
                  jq -r '.[].ResourceRecords' | sed 's/\[//g' | sed 's/\]//g')

            if [ -z "${current_records}" ]; then
               new_records='{
    "Value": "'${IP}'"
}'
            else
               new_records='{
    "Value": "'${IP}'"
},
 '${current_records}
            fi

            aws ${AWS_ARGS} route53 change-resource-record-sets \
               --hosted-zone-id "${HOSTED_ZONE_ID}" \
               --change-batch file://<(cat << EOF
{
  "Comment": "Creating A record ${RECORD}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${RECORD}.${HOSTED_ZONE_NAME}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          ${new_records}
        ]
      }
    }
  ]
}
EOF
) > /dev/null 2>&1


            if [ ${retVal} -ne 0 ]; then
               secs_now=$(date +'%s')
               echo "Waiting for AWS DNS record \"${RECORD}\" to be created  - ($(expr ${secs_now} - ${start_secs}) seconds)"
            else
               echo "AWS DNS Record successfully updated at $(date)"
            fi
         done
      fi
   fi
}

function delete_route53_record() {
   RECORD=$1
   IP=$2
   HOSTED_ZONE_ID=$3
   TYPE=$4

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      echo "delete_route53_a_record not available for Azure"
      return 0
   fi

   aws ${AWS_ARGS} route53 change-resource-record-sets \
         --hosted-zone-id "${HOSTED_ZONE_ID}" \
         --change-batch file://<(cat << EOF
{
  "Comment": "Deleting record ${RECORD}",
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "${RECORD}",
        "Type": "${TYPE}",
        "TTL": 120,
        "ResourceRecords": [
          {
            "Value": "${IP}"
          }
        ]
      }
    }
  ]
}
EOF
)

}

function get_server_number() {

   param_name=$1

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      aws ${AWS_ARGS} ssm put-parameter --region ${region} --type "String" \
            --name "${param_name}" \
            --value ${instance_id} --overwrite --output text | \
            awk '{if ($2>0) print $2-1; else print "1"}'
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $1 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      az keyvault secret set \
         --name "${param_name}" \
         --vault-name "${region}-${CUSTOMER}-${ENVIRONMENT}" \
         --value "new instance" \
         --query "version"
   fi

   if [[ ! ${server_number} =~ ^[0-9]+$ ]]; then
      echo 1
   fi
}

function put_ssm() {

   ssm_region=$1
   param_name=$2
   param_value=$3
   other_options=$4

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      aws ${AWS_ARGS} ssm put-parameter \
            --cli-read-timeout ${AWS_CLI_READ_TIMEOUT} \
            --cli-connect-timeout ${AWS_CLI_CONNECT_TIMEOUT} \
            ${other_options} --region ${ssm_region} \
            --type "String" \
            --name "${param_name}" \
            --value "${param_value}"

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $2 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      if [ "${other_options}" != "--overwrite" ]; then
         az keyvault secret show \
            --name "${param_name}" \
            --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" > /dev/null 2>&1
   
         if [ $? -eq 0 ]; then
            return 1
         fi
      fi

      az keyvault secret set \
         --name "${param_name}" \
         --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" \
         --value "${param_value}" 2> /dev/null

      return $?
   fi
}

function put_secure_ssm() {

   ssm_region=$1
   param_name=$2
   param_value=$3
   other_options=$4

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ssm put-parameter \
            --cli-read-timeout ${AWS_CLI_READ_TIMEOUT} \
            --cli-connect-timeout ${AWS_CLI_CONNECT_TIMEOUT} \
            ${other_options} --region ${ssm_region} \
            --type "SecureString" \
            --name "${param_name}" \
            --value "${param_value}"

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $2 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      if [ "${other_options}" != "--overwrite" ]; then
         az keyvault secret show \
            --name "${param_name}" \
            --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" > /dev/null 2>&1
   
         if [ $? -eq 0 ]; then
            return 1
         fi
      fi
   
      az keyvault secret set \
         --name "${param_name}" \
         --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" \
         --value "${param_value}" 2> /dev/null
   
      return $?
   fi
}

function get_ssm() {

   ssm_region=$1
   param_name=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ssm get-parameter \
            --cli-read-timeout ${AWS_CLI_READ_TIMEOUT} \
            --cli-connect-timeout ${AWS_CLI_CONNECT_TIMEOUT} \
            --output text \
            --region "${ssm_region}" \
            --name "${param_name}" \
            --query 'Parameter.Value' 2> /dev/null 

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $2 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      az keyvault secret show \
         --name "${param_name}" \
         --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" \
         --output tsv \
         --query "value" 2> /dev/null

      return $?
   fi
}

function get_secure_ssm() {
   ssm_region=$1
   param_name=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ssm get-parameter \
            --cli-read-timeout ${AWS_CLI_READ_TIMEOUT} \
            --cli-connect-timeout ${AWS_CLI_CONNECT_TIMEOUT} \
            --output text \
            --region "${ssm_region}" \
            --name "${param_name}" \
            --query 'Parameter.Value' \
            --with-decryption 2> /dev/null

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $2 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      az keyvault secret show \
         --name "${param_name}" \
         --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" \
         --output tsv \
         --query "value" 2> /dev/null

      return $?
   fi
}

function delete_ssm() {
   ssm_region=$1
   param_name=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ssm delete-parameter \
            --name "${param_name}" \
            --region "${ssm_region}" > /dev/null 2>&1

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      param_name=$(echo $2 | sed 's#/#-#g' | sed 's#^-##g' | sed 's#_#-#g')

      az keyvault secret delete \
          --name "${param_name}" \
          --vault-name "${ssm_region}-${CUSTOMER}-${ENVIRONMENT}" > /dev/null 2>&1

      return $?
   fi
}

function get_running_instances() {
   ssm_region=$1
   instance_name=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 describe-instances \
            --region ${ssm_region} \
            --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*-"${instance_name}"-*" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output=text
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then

      az vmss nic list \
          --resource-group "${CUSTOMER}-${ENVIRONMENT}-resource-group" \
          --vmss-name "${REGION_ALIAS}-${instance_name}" 2> /dev/null | \
          jq -r '.[].ipConfigurations | .[].privateIPAddress'
   fi

}

function get_last_stored_file() {

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      storage_name=$1
      bucket_name="${storage_name}"

      aws ${AWS_ARGS} s3api list-objects-v2 \
            --bucket "${bucket_name}" | \
            jq  -c ".[] | max_by(.LastModified)|.Key" | \
            sed 's/"//g' | \
            sed 's/backup\///'
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      storage_name=$(echo $1 | sed 's/\./-/g')

      BLOB_STORAGE_ACCOUNT_NAME="${REGION}${CUSTOMER}"
      BLOB_RESOURCE_GROUP_NAME="${CUSTOMERS}-${ENVIRONMENT}-resource-group"
      BLOB_CONTAINER_NAME="${storage_name}"

      blob_account_key=$(az storage account keys list \
                       --resource-group "${CUSTOMER}-${ENVIRONMENT}-resource-group" \
                       --account-name "${REGION}${CUSTOMER}" \
                       --query '[0].value' -o tsv)

      az storage blob list \
          --container-name "${storage_name}" \
          --account-key "${blob_account_key}" \
          --account-name "${REGION}${CUSTOMER}" | jq -r '.[].name' | \
          sort -n | tail -1
   fi
}

function get_storage_list() {

   storage_name=$1

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} s3 ls ${storage_name} 2> /dev/null | \
            sed 's/"//g' | \
            sort -n
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      storage_name=$(echo $1 | sed 's/\./-/g')

      BLOB_STORAGE_ACCOUNT_NAME="${REGION}${CUSTOMER}"
      BLOB_RESOURCE_GROUP_NAME="${CUSTOMERS}-${ENVIRONMENT}-resource-group"
      BLOB_CONTAINER_NAME="${storage_name}"

      blob_account_key=$(az storage account keys list \
                       --resource-group "${CUSTOMER}-${ENVIRONMENT}-resource-group" \
                       --account-name "${REGION}${CUSTOMER}" \
                       --query '[0].value' -o tsv)

      az storage blob list \
          --container-name "${storage_name}" \
          --account-key "${blob_account_key}" \
          --account-name "${REGION}${CUSTOMER}" | \
          jq -r '.[] | .properties.creationTime[:19] + " " + (.properties.contentLength | tostring) +" " + .name' | \
          sed 's/T/:/' | \
          sed 's/:/ /' | \
          sort -n
   fi
}

function rename_stored_file() {

   storage_name=$1
   old_file=$2
   new_file=$3

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      aws ${AWS_ARGS} s3 mv ${storage_name}/${old_file} ${storage_name}/${new_file} > /dev/null 2>&1
      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      storage_name=$(echo $1 | sed 's/\./-/g')

      BLOB_STORAGE_ACCOUNT_NAME="${REGION}${CUSTOMER}"
      BLOB_RESOURCE_GROUP_NAME="${CUSTOMERS}-${ENVIRONMENT}-resource-group"
      BLOB_CONTAINER_NAME="${storage_name}"

      blob_account_key=$(az storage account keys list \
                       --resource-group "${CUSTOMER}-${ENVIRONMENT}-resource-group" \
                       --account-name "${REGION}${CUSTOMER}" \
                       --query '[0].value' -o tsv)

echo "cannot yet rename_stored_file with azure"
#      az storage blob list \
#          --container-name "${storage_name}" \
#          --account-key "${blob_account_key}" \
#          --account-name "${REGION}${CUSTOMER}" | \
#          jq -r '.[] | .properties.creationTime + " " + .name' | \
#          sed 's/T/ /' | sed 's/+/ /' | \
#          sort -n
   fi
}

function delete_stored_file() {

   storage_name=$1
   file_to_delete=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      aws ${AWS_ARGS} s3 rm ${storage_name}/${file_to_delete} > /dev/null 2>&1
      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      storage_name=$(echo $1 | sed 's/\./-/g')

      BLOB_STORAGE_ACCOUNT_NAME="${REGION}${CUSTOMER}"
      BLOB_RESOURCE_GROUP_NAME="${CUSTOMERS}-${ENVIRONMENT}-resource-group"
      BLOB_CONTAINER_NAME="${storage_name}"

      blob_account_key=$(az storage account keys list \
                       --resource-group "${CUSTOMER}-${ENVIRONMENT}-resource-group" \
                       --account-name "${REGION}${CUSTOMER}" \
                       --query '[0].value' -o tsv)

      az storage blob delete \
          --account-name "${REGION}${CUSTOMER}" | \
          --container-name "${storage_name}" \
          --account-key "${blob_account_key}" \
          --name "${file_to_delete}"

      return $?
   fi
}

function get_stored_file() {

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then
      storage_name=$1
      file_name=$2
      destination=$3

echo "AWS_ARGS is \"${AWS_ARGS}\", get_stored_file $*"
echo "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
      aws ${AWS_ARGS} s3 ls "s3://${storage_name}"
echo "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
      aws ${AWS_ARGS} s3 cp "s3://${storage_name}/${file_name}" ${destination} # > /dev/null 2>&1
      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      blob_container_name=$1
      file_name=$2
      destination=$3
      blob_storage_account_name=$4
      blob_resource_group_name=$5

      account_key=$(az storage account keys list \
                       --resource-group ${blob_resource_group_name} \
                       --account-name ${blob_storage_account_name} \
                       --query '[0].value' -o tsv 2> /dev/null)

      az storage blob download \
          --account-name "${blob_storage_account_name}" \
          --container-name "${blob_container_name}" \
          --name "${file_name}" \
          --file "${destination}" \
          --account-key "${account_key}" > /dev/null 2>&1

      return $?
   fi
}

function store_file() {

   blob_container_name=$1
   file_name=$2
   destination=$3
   blob_storage_account_name=$4
   blob_resource_group_name=$5
   tag_key=$6
   tag_value=$7

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      if [ -z "${tag_key}" -o -z "${tag_value}" ]; then
         tag_key="Uploaded"
         tag_value="$(date)"
      fi

      aws ${AWS_ARGS} s3 cp "${file_name}" "s3://${blob_container_name}" > /dev/null 2>&1
      retval=$?

      aws ${AWS_ARGS} s3api put-object-tagging \
         --bucket "${blob_container_name}" \
         --key "${file_name}" \
         --tagging '{"TagSet": [{ "Key": "'${tag_key}'", "Value": "'${tag_value}'" }]}' > /dev/null 2>&1

      return ${retVal}
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then

      if [ -z "${tag_key}" -o -z "${tag_value}" ]; then
         tag_key="Uploaded"
         tag_value="$(date)"
      fi

      account_key=$(az storage account keys list \
                    --resource-group ${blob_resource_group_name} \
                    --account-name ${blob_storage_account_name} \
                    --query '[0].value' -o tsv 2> /dev/null)

      if [ $? -ne 0 -o -z "${account_key}" ]; then
         echo "Failed to obtain account_key for ${blob_storage_account_name}"
         return 1
      fi
  
      az storage blob upload \
          --account-name "${blob_storage_account_name}" \
          --container-name "${blob_container_name}" \
          --name "${destination}" \
          --file "${file_name}" \
          --tags ${tag_key}="${tag_value}" \
          --account-key "${account_key}" > /dev/null 2>&1

      return $?
   fi
}

function get_resource_tag() {

   ssm_region=$1
   instance=$2
   tag=$3

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 describe-tags \
            --region "${ssm_region}" \
            --filters "Name=resource-id,Values=${instance}" "Name=key,Values=${tag}" \
            --query Tags[].Value \
            --output text 2> /dev/null

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then

      az vm show --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group \
           --name ${instance} \
           --query tags.${tag} \
           --output tsv 2> /dev/null

      return $?
   fi

}

function create_resource_tag() {

   ssm_region=$1
   instance=$2
   key=$3
   value=$4

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 create-tags \
            --region "${ssm_region}" \
            --resources "${instance}" \
            --tags Key="$3,Value=$4" > /dev/null 2>&1

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      resource_id="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${CUSTOMER}-${ENVIRONMENT}-resource-group/providers/Microsoft.Compute/virtualMachines/${instance}"

      az tag update \
         --operation merge \
         --resource-id ${resource_id} \
         --tags ${key}=${value} >> /tmp/tag-updates 2>&1

      return $?
   fi
}

function get_instance_status() {
   ssm_region=$1
   instance=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 describe-instances \
            --region ${ssm_region} \
            --instance-ids ${instance} \
            --query 'Reservations[].Instances[].State.Name' \
            --output text  2> /dev/null

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      host_check=$(az vm list --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group -d | \
           jq -r '.[] | select(IN(.name; "'${instance}'")) | .name')

      if [ "${host_check}" == "${instance}" ]; then
         echo "running"
      else
         echo "unknown-status"
      fi
   fi
}

function get_running_instance() {

   ssm_region=$1
   instance=$2

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 describe-instances \
            --filters "Name=instance-id,Values=${instance}" \
            --region ${ssm_region} \
            --query 'Reservations[*].Instances[*].InstanceId' \
            --output text 2> /dev/null

      return $?
   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      echo ${instance}
      return $?
   fi
}

function get_instance_with_status() {
   ssm_region=$1
   server=$2
   status=$3

   if [ "${CLOUD_PLATFORM}" == "aws" ]; then

      aws ${AWS_ARGS} ec2 describe-instances \
            --region "${ssm_region}" \
            --filters "Name=tag:ServerType,Values=${server}" \
                      "Name=tag:Status,Values=${status}" \
                      "Name=instance-state-name,Values=running,pending" | \
            jq ".Reservations[].Instances[].InstanceId" | sed 's/"//g'

   fi

   if [ "${CLOUD_PLATFORM}" == "azure" ]; then
      az vm list --resource-group ${CUSTOMER}-${ENVIRONMENT}-resource-group -d | \
        jq -r '.[] | select(IN(.tags.ServerType; "'${server}'")) | select(IN(.tags.Status; "'${status}'")) | select(IN(.location; "'${ssm_region}'")) | .name'
   fi
}
