#!/bin/bash

AMI_PREFIX="AIL"
BASE_OS="debian-12"
TLD="/Users/grenvillewhelan/AccessIdentified/BT"
PACKER_DIR=${TLD}/packer

if [ ! -d ${PACKER_DIR} ]; then
   red_echo "$0: Warning cannot access ${PACKER_DIR}, exiting"
   exit 1
fi

cd ${PACKER_DIR}

while getopts 'A:P:a:d:k:p:r:' opt; do

   case "${opt}" in

   A)
      # The additional AWS regions which the primary build at REGION will be replicated to
      # by packer

      AMI_REGIONS=${OPTARG}
      ;;

   P)
      # The prefix for AMI names to be created
      AMI_PREFIX=${OPTARG}
      ;;

   a)
      # The 12 digit AWS account number dedicated the above customer and environment.
      # The default is "762233743855".

      ACCOUNT=${OPTARG}
      ;;

   d)
      # BASE_OS alternative, e.g. "debian-11"
      # The default is "debian-12"

      BASE_OS=${OPTARG}
      ;;

   k)
      # alias/shared-disk-encryption

      KMS=${OPTARG}
      ;;

   p)
      # The AWS profile which contains the appropriate credentials. Conventional
      # format is "<customer>_<environment>".

      PROFILE=${OPTARG}
      ;;

   r)
      # The AWS region in which to deploy the stack. The default is "eu-west-1".

      REGION=${OPTARG}
      ;;

    ?|h)
      echo "usage: $0 [options]  <images>"
      echo
      echo "Options:"
      echo "             -a <aws_account_number>"
      echo "             -d <BASE_OS>"
      echo "             -k <kms_key_id>"
      echo "             -p <aws_profile>"
      echo "             -r <aws_region>"
      echo "             -A <aws_regions>"
      echo "             -P <ami_prefix>"
      exit 1
      ;;

   esac
done

shift "$((${OPTIND} -1))"

IMAGES=$*

[[ -z ${PROFILE} ]] && PROFILE="packer"
[[ -z ${ACCOUNT} ]] && ACCOUNT="762233743855"
[[ -z ${REGION} ]] && REGION="eu-west-1"

TAG_VERSION=$(git describe --tags 2> /dev/null)

if [ -z "${TAG_VERSION}" ]; then
   TAG_VERSION="test-no-tag"
fi

echo "Calling packer with the following inputs:"
echo "  profile:        ${PROFILE}"
echo "  aws_account:    ${ACCOUNT}"
echo "  base_os:    ${BASE_OS}"
echo "  region:         ${REGION}"
echo "  ami_regions:    ${AMI_REGIONS}"
echo "  AMI prefix:     \"${AMI_PREFIX}\""
echo "  images:         $IMAGES"
echo ""

if [ -n "${IMAGES}" ]; then
    packer build -only "*.amazon-ebs.ail-${IMAGES}" \
                 -var "profile=${PROFILE}" \
                 -var "aws_account=${ACCOUNT}" \
                 -var "region=${REGION}" \
                 -var "ami_regions=${AMI_REGIONS}" \
                 -var "tag_version=${TAG_VERSION}" \
                 -var "base_os=${BASE_OS}" \
                 -var "ami_prefix=${AMI_PREFIX}" ${KMS_KEY} .
    exit $?
else
    if [ "${AMI_PREFIX}" == "ail" ]; then
       packer build -only "*.amazon-ebs.ail-base" \
                 -var "profile=${PROFILE}" \
                 -var "aws_account=${ACCOUNT}" \
                 -var "region=${REGION}" \
                 -var "ami_regions=${AMI_REGIONS}" \
                 -var "tag_version=${TAG_VERSION}" \
                 -var "base_os=${BASE_OS}" \
                 -var "ami_prefix=${AMI_PREFIX}" ${KMS_KEY} .

       if [ $? -ne 0 ]; then
          echo "Failed to build *.amazon-ebs.ail-arm-base, exiting"
          exit $?
       fi
    fi

    packer build -except "*.amazon-ebs.ail-base" \
                 -var "profile=${PROFILE}" \
                 -var "aws_account=${ACCOUNT}" \
                 -var "region=${REGION}" \
                 -var "ami_regions=${AMI_REGIONS}" \
                 -var "tag_version=${TAG_VERSION}" \
                 -var "base_os=${BASE_OS}" \
                 -var "ami_prefix=${AMI_PREFIX}" ${KMS_KEY} .
    exit $?
fi
