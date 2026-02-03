#!/bin/bash

SG_ID="sg-04303efbdaed5c6f9"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z02030392LMN8KQVWR9UZ"  #Route53 Hosted Zone ID
DOMAIN_NAME="dawsmani.site"

instance=("mysql" "backend" "frontend")

for name in ${instance[@]}
do
    # Creating instance for given component
    INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" \
    --query 'Instances[0].InstanceId' \
    --output text 
    )

    if [ $name == frontend ]; then
    IP=$(
        aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME=$DOMAIN_NAME
    else
    IP=$(
        aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME=$name.$DOMAIN_NAME

        echo "Creating Route53 Record for $name with IP $IP"
    fi

    # UPSERT:: If record available just update, if not available just create it
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }
    '
    echo "Record updated for $name with IP $IP"
    echo "--------------------------------"
    echo ""
done