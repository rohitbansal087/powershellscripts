#!/bin/bash

terraform show -json tfplan > terraformplan.json

RESOURCE_CHANGES_LENGTH=`cat terraformplan.json | jq '.resource_changes | length'`

##Variables

for (( i=0; i<${RESOURCE_CHANGES_LENGTH}; i++ ))
do

ACTION=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.actions[]"`
TYPE=`cat terraformplan.json | jq -r ".resource_changes[${i}].type"`
IP_ADDRESS=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.before.private_ip_address"`
IP_ADDRESS=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.before.name"`

if [ ${ACTION} == "delete" ] && [ ${TYPE} == "azurerm_virtual_machine" ]
then

##Command
##Command
fi
