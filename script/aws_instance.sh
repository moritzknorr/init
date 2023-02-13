#!/bin/sh
read -p 'Profile [aventa]: ' PROFILE
echo 'Available instance types: '
echo 'ARM: t4g.small (2 Gb), t4g.large (16 Gb), t4g.2xlarge (32 Gb)'
echo 'x64: t3.small (2 Gb), t3.xlarge (8 Gb), t3.2xlarge (32 Gb), c5.12xlarge (96 Gb)'
read -p 'Instance Type [t4g.micro]: ' TYPE
read -p 'Instance Architecture [arm]: ' ARCHITECTURE
read -p 'Mount Volume [n]: ' MOUNT

TYPE=${TYPE:-t4g.micro}
PROFILE=${PROFILE:-aventa}
MOUNT=${MOUNT:-n}
ARCHITECTURE=${ARCHITECTURE:-arm}

if [ ${PROFILE} = "default" ]; then
  VOLUMEID=vol-0e2c6c00585750b66
  SUBNETID=subnet-103ead6a
  SECURITYGROUPID=sg-2dec4040
elif [ ${PROFILE} = "aventa" ]; then
  SUBNETID=subnet-038cb2955e222a20b
  SECURITYGROUPID=sg-02c4d52f2203b0203
else
  VOLUMEID=vol-07cc8faa856eb1ffe
  SUBNETID=subnet-09998f9d67efdbf79
  SECURITYGROUPID=sg-0b1a8396943ea3572
fi

if [ ${ARCHITECTURE} = "arm" ]; then
  IMAGEID=ami-0b4b0a5bd04aec558
else
  # x64
  IMAGEID=ami-0a49b025fffbbdac6
fi

read -p "Start ${TYPE} instance with ${PROFILE} profile and ${MOUNT} mount [type: yes]: " DO

if [ ! "${DO}" = "yes" ]; then
  echo 'Stop here'
  exit 0
fi

INSTANCE=$(aws --profile ${PROFILE} --region eu-central-1 ec2 run-instances --instance-type "${TYPE}" --image-id "${IMAGEID}" --subnet-id "${SUBNETID}" --security-group-ids "${SECURITYGROUPID}" --cli-input-json file://instance.json)
sleep 2

INSTANCEID=$(echo "${INSTANCE}" | grep InstanceId | grep -oP "(i-[a-z0-9]*)")

if [ "${PROFILE}" = "work" ]; then
  # get IDs for tags
  NETWORKINTERFACEID=$(echo "${INSTANCE}" | grep NetworkInterfaceId | grep -oP "(eni-[a-z0-9]*)")
  TEMPVOLUMEID=$(aws --profile ${PROFILE} --region eu-central-1 ec2 describe-instances --instance-ids ${INSTANCEID} | grep VolumeId | grep -oP "(vol-[a-z0-9]*)")
  aws --profile ${PROFILE} --region eu-central-1 ec2 create-tags --resources ${INSTANCEID} ${TEMPVOLUMEID} ${NETWORKINTERFACEID} --cli-input-json file:///home/knorr/aws_tags_work.json
fi

# Wait for instance
sleep 15

if [ "${MOUNT}" = "y" ]; then
  aws --profile ${PROFILE} --region eu-central-1 ec2 attach-volume --device /dev/sdx --instance-id ${INSTANCEID} --volume-id $VOLUMEID
fi

IP=$(aws --profile ${PROFILE} --region eu-central-1 ec2 describe-instances --instance-ids ${INSTANCEID} --query "Reservations[*].Instances[*].PublicIpAddress" | grep -oP "([0-9.]*)")
echo "scp -r ~/.aws ${IP}: && ssh -L 22:localhost:22 -L 8888:localhost:8888 -A ${IP}"
