#!/bin/sh
echo 'Available instance types: '
echo 'ARM: t4g.small (2 Gb), t4g.large (16 Gb), t4g.2xlarge (32 Gb)'
echo 'x64: t3.small (2 Gb), t3.xlarge (8 Gb), t3.2xlarge (32 Gb), c5.12xlarge (96 Gb)'
read -p 'Instance Type [t4g.micro]: ' TYPE
read -p 'Instance Architecture [arm]: ' ARCHITECTURE

TYPE=${TYPE:-t4g.micro}
ARCHITECTURE=${ARCHITECTURE:-arm}

if [ ${ARCHITECTURE} = "arm" ]; then
  IMAGEID=ami-0b4b0a5bd04aec558
else
  # x64
  IMAGEID=ami-0a49b025fffbbdac6
fi

read -p "Start ${TYPE} instance: " DO

if [ ! "${DO}" = "yes" ]; then
  echo 'Stop here'
  exit 0
fi

INSTANCE=$(aws --region eu-central-1 ec2 run-instances --instance-type "${TYPE}" --image-id "${IMAGEID}" --subnet-id "${SUBNETID}" --security-group-ids "${SECURITYGROUPID}" --cli-input-json file://instance.json)
sleep 2

INSTANCEID=$(echo "${INSTANCE}" | grep InstanceId | grep -oP "(i-[a-z0-9]*)")

# Wait for instance
sleep 15

IP=$(aws --region eu-central-1 ec2 describe-instances --instance-ids ${INSTANCEID} --query "Reservations[*].Instances[*].PublicIpAddress" | grep -oP "([0-9.]*)")
echo "ssh -A ${IP}"
