#!/bin/bash

URL=`aws ec2 describe-instances  --filters "Name=tag:Name,Values=DEV_ENV_EC2_INSTANCE" | jq .Reservations[].Instances[].PublicIpAddress| tr -d '"'`

if [[ $URL != '' ]]; then
        liveness=$(curl -S -o /dev/null -w %{http_code} http://$URL/live)
        echo $liveness
        app_data=$(curl -XPOST http://$URL/planet -H 'Content-Type: application/json' -d '{"id": "3"}')
        echo $app_data
        name_to_id=$(echo $app_data | jq -r .name)
        echo $name_to_id
        if [[ $liveness -eq "200" && $name_to_id -eq "Earth" ]]; then
                echo "test passed!"
        else
                echo "failure"
        fi;
else
        echo "No Ip found for this instance"
        exit 1
fi

