#!/bin/sh

ENV="aventa-dev"

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

read -p "Start ${TYPE} instance, type yes: " DO

if [ ${ENV} = "aventa-dev" ]; then
  SUBNETID=subnet-038cb2955e222a20b
  SECURITYGROUPID=sg-02c4d52f2203b0203
elif [ ${ENV} = "aventa-prod" ]; then
  SUBNETID=subnet-0375a63dc988121ae
  SECURITYGROUPID=sg-025c5b3bfeb6ffee5
elif [ ${ENV} = "aventapharm" ]; then
  SUBNETID=subnet-0093491461c0c0bf4
  SECURITYGROUPID=sg-001f88f0df2ad4b92
else
  exit 1
fi

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
