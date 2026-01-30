#!/bin/sh

: > /etc/fck-nat.conf
if [ -n "${TERRAFORM_ENI_ID}" ]; then
  echo "eni_id=${TERRAFORM_ENI_ID}" >> /etc/fck-nat.conf
fi
echo "eip_id=${TERRAFORM_EIP_ID}" >> /etc/fck-nat.conf
echo "cwagent_enabled=${TERRAFORM_CWAGENT_ENABLED}" >> /etc/fck-nat.conf
echo "cwagent_cfg_param_name=${TERRAFORM_CWAGENT_CFG_PARAM_NAME}" >> /etc/fck-nat.conf
echo "gwlb_enabled=${TERRAFORM_GWLB_ENABLED}" >> /etc/fck-nat.conf
echo "gwlb_health_check_port=${TERRAFORM_GWLB_HEALTH_CHECK_PORT}" >> /etc/fck-nat.conf

# Disable source/dest check on the instance's ENI when GWLB is enabled
if [ "${TERRAFORM_GWLB_ENABLED}" = "true" ]; then
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
  MAC=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/mac)
  ENI_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/interface-id")
  aws ec2 modify-network-interface-attribute --network-interface-id "$ENI_ID" --no-source-dest-check
fi

service fck-nat restart
