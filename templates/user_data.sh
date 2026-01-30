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

service fck-nat restart
