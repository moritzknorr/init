#!/bin/sh
read -p 'Profile [default]: ' PROFILE
read -p 'Instance Type [t3.medium]: ' TYPE
read -p 'Mount Volume [y]: ' MOUNT

TYPE=${TYPE:-t3.medium}
PROFILE=${PROFILE:-default}
MOUNT=${MOUNT:-y}

if [ ${PROFILE} = "default" ]; then
  VOLUMEID=vol-0e2c6c00585750b66
  SUBNETID=subnet-103ead6a
  SECURITYGROUPID=sg-2dec4040
else
  VOLUMEID=vol-07cc8faa856eb1ffe
  SUBNETID=subnet-09998f9d67efdbf79
  SECURITYGROUPID=sg-0b1a8396943ea3572
fi

read -p "Start ${TYPE} instance with ${PROFILE} profile and ${MOUNT} mount [type: yes]: " DO

if [ ! "${DO}" = "yes" ]; then
  echo 'Stop here'
  exit 0
fi

INSTANCE=$(aws --profile ${PROFILE} --region eu-central-1 ec2 run-instances --instance-type "${TYPE}" --subnet-id "${SUBNETID}" --security-group-ids "${SECURITYGROUPID}" --cli-input-json file://instance.json)
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
echo "ssh -A ${IP}"

