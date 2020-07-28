#!/bin/bash

RESOURCE_CHANGES_LENGTH=`cat terraformplan.json | jq '.resource_changes | length'`
username="sapapiadm"
password="699rrCPu8"
baseuri="https://infoblox-api.wal-mart.com/wapi/v2.5"
username1="sap-api"
password1=$infobloxpwd1
baseuri1="https://azure-infoblox-api.us.walmart.net/wapi/v2.5"

for (( i=0; i<${RESOURCE_CHANGES_LENGTH}; i++ ))
do

    ACTION=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.actions[]"`
    TYPE=`cat terraformplan.json | jq -r ".resource_changes[${i}].type"`
    IP_ADDRESS=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.before.private_ip_address"`
    HOSTNAME=`cat terraformplan.json | jq -r ".resource_changes[${i}].change.before.name"`

    if [ ${ACTION} == "delete" ] && [ ${TYPE} == "azurerm_virtual_machine" ]
    then

        checkuri="$baseuri/record:a?name=${HOSTNAME}.cloud.wal-mart.com"
        content=`curl -u sapapiadm:699rrCPu8 --request GET -H "Accept: application/json" ${checkuri} -k | jq  -r '.[]._ref'`

        if [ ! -z ${content} ]
        
            curl -u sapapiadm:699rrCPu8 --request DELETE -H "Accept: application/json" https://infoblox-api.wal-mart.com/wapi/v2.5/${content} -k
        
        fi
    fi        

    if [ ${ACTION} == "delete" ] && [ ${TYPE} == "azurerm_network_interface" ]
    then
        checkuri1="$baseuri1/record:ptr?ipv4addr=${IP_ADDRESS}"
        content1=`curl -u sapapiadm:699rrCPu8 --request GET -H "Accept: application/json" ${checkuri1} -k | jq  -r '.[]._ref'`
        
        if [ ! -z ${content} ]

            curl -u sapapiadm:${infobloxpwd1} --request DELETE -H "Accept: application/json" https://infoblox-api.wal-mart.com/wapi/v2.5/${content1} -k

        fi

    fi


done
