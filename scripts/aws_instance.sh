#!/bin/bash

CONFIG="$(dirname "$0")/aws_config.sh"
if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG — copy aws_config.sh.example and fill in your values."
  exit 1
fi
. "$CONFIG"

echo 'Available instance types: '
echo 'ARM: t4g.small (2 Gb), t4g.medium (4gb), t4g.large (16 Gb), t4g.2xlarge (32 Gb)'
echo 'x64: t3.small (2 Gb), t3.xlarge (8 Gb), t3.2xlarge (32 Gb), c5.12xlarge (96 Gb)'
read -p 'Environment [agencio-dev]: ' ENV
read -p 'Instance Type [t4g.micro]: ' TYPE
read -p 'Instance Architecture [arm]: ' ARCHITECTURE

ENV=${ENV:-agencio-dev}
TYPE=${TYPE:-t4g.micro}
ARCHITECTURE=${ARCHITECTURE:-arm}

if [ "${ARCHITECTURE}" = "arm" ]; then
  IMAGEID=ami-0df5c15a5f998e2ab
else
  IMAGEID=ami-01f79b1e4a5c64257
fi

SUBNETID="${SUBNET_IDS[$ENV]}"
SECURITYGROUPID="${SECURITY_GROUP_IDS[$ENV]}"

if [ -z "$SUBNETID" ] || [ -z "$SECURITYGROUPID" ]; then
  echo "Unknown environment: ${ENV}"
  exit 1
fi

read -p "Start ${TYPE} instance in ${ENV}, type yes: " DO
if [ ! "${DO}" = "yes" ]; then
  echo 'Aborted.'
  exit 0
fi

INSTANCE=$(aws --profile "${ENV}" --region eu-central-1 ec2 run-instances \
  --instance-type "${TYPE}" \
  --image-id "${IMAGEID}" \
  --subnet-id "${SUBNETID}" \
  --security-group-ids "${SECURITYGROUPID}" \
  --cli-input-json file://instance.json)
sleep 2

INSTANCEID=$(echo "${INSTANCE}" | grep InstanceId | grep -oP "(i-[a-z0-9]*)")

sleep 15

IP=$(aws --profile "${ENV}" --region eu-central-1 ec2 describe-instances \
  --instance-ids "${INSTANCEID}" \
  --query "Reservations[*].Instances[*].PublicIpAddress" | grep -oP "([0-9.]*)")
echo "ssh -A ${IP}"
