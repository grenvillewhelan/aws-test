  AWS_PROFILE=packer
  AMI_ACCOUNT_OWNER=762233743855
  AMI_PREFIX="AIL"
  customer_name="bt"
  environment_name="dev"
  dns_suffix="accessidentifiedcloud.com"
  PRIMARY_REGION=eu-west-1
  OTHER_REGIONS='["eu-west-1"]'
  OS_BASE_AWS=ubuntu-jammy-22.04-arm64-server
  OS_BASE_AWS_WINDOWS="Windows_Server-2022-English-Core-Base"

  ARM_ACCOUNT_KEY="no-azure-not-applicable"
  ARM_CLIENT_ID="no-azure-not-applicable"
  ARM_CLIENT_SECRET="no-azure-not-applicable"
  ARM_SUBSCRIPTION_ID="a892d455-55f8-4480-9e0f-594266d96b54"
  ARM_TENANT_ID="32e7422c-0a0d-48fd-b631-e2f22d217eff"
  TAG_VERSION="v1.0.0e"

packer build \
   -only "*.amazon-ebs.${AMI_PREFIX}-cyberark" \
   -var "profile=${AWS_PROFILE}" \
   -var "aws_account=${AMI_ACCOUNT_OWNER}" \
   -var "region=${PRIMARY_REGION}" \
   -var "customer_name=${customer_name}" \
   -var "environment_name=${environment_name}" \
   -var "dns_suffix=${dns_suffix}" \
   -var "ami_prefix=${AMI_PREFIX}" \
   -var "ami_regions=${OTHER_REGIONS}" \
   -var "tag_version=${TAG_VERSION}" \
   -var "aws_secret_access_key=${aws_secret_access_key}" \
   -var "aws_access_key_id=${aws_access_key_id}" \
   -var "os_base=${OS_BASE_AWS}" \
   -var "os_base_win=${OS_BASE_AWS_WINDOWS}" \
   -var "subscription_id=${ARM_SUBSCRIPTION_ID}" \
   -var "tenant_id=${ARM_TENANT_ID}" \
   -var "client_id=${ARM_CLIENT_ID}" \
   -var "client_secret=${ARM_CLIENT_SECRET}" \
   .


