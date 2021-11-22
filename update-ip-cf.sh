#!/bin/sh
####################################################################
# Script Name   : update-ip-cf.sh
# Description   : Update the Cloudflare Zone Record with the external
#               : IP of the machine where it runs.
#               : The log is via journald as it use timerd not cron.
# Args          : Use the .conf file to specify all parameters.
# Author        : Gerardo Gonzalez
# Email         : gerardoj.gonzalezg@bigg.blog
####################################################################

# Defining the colors sequences
# you can update this to tput
#
GREEN="\e[38;5;46m"
BLUE="\e[38;5;39m"
RED="\e[38;5;196m"
STOP="\e[0m"

#
# Config File
#
CONFIG_FILE="update-ip-cf.conf"
if [ ! -e $CONFIG_FILE ]
then
    printf "${RED}Config File $CONFIG_FILE not found.${STOP}\n"
    exit 1
fi

#
# Get the external IP
#
NEW_IP=`curl -s http://whatismyip.akamai.com/`

#
# Get the Last Know IP
#
LAST_IP=`cat $CONFIG_FILE | grep -Po '^LAST_IP\="?\K(([0-9]{1,3}\.){3}[0-9]{1,3})'`

#
# Check if requieres an update (to reduce API calls)
#
if [ "$NEW_IP" = "$LAST_IP" ]
then
    printf "${BLUE}No update needed, current IP is: ${GREEN}$NEW_IP${STOP}\n"
else
    printf "${BLUE}Updating IP from: $LAST_IP to: ${GREEN}$NEW_IP${STOP}\n"
    # Get the config parameters,  X-Auth-Email
    AUTH_EMAIL=`cat $CONFIG_FILE | grep -Po 'AUTH_EMAIL="?\K[^"?]*'`
    # X-Auth-Key2Y
    AUTH_KEY=`cat $CONFIG_FILE | grep -Po 'AUTH_KEY="?\K[^"?]*'`
    # zone_identifier
    ZONE_ID=`cat $CONFIG_FILE | grep -Po '^ZONE_ID="?\K[^"?]*'`
    # dns_records identifier
    RECORD_ID=`cat $CONFIG_FILE | grep -Po '^RECORD_ID="?\K[^"?]*'`
    # type
    TYPE=`cat $CONFIG_FILE | grep -Po '^TYPE="?\K[^"?]*'`
    # name
    NAME=`cat $CONFIG_FILE | grep -Po '^NAME="?\K[^"?]*'`

    #
    # Calling the CF API to update the IP
    #
    RESULT=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
         -H "X-Auth-Email: $AUTH_EMAIL" \
         -H "X-Auth-Key: $AUTH_KEY" \
         -H "Content-Type: application/json" \
	 --data '{"type":"'"$TYPE"'","name":"'"$NAME"'","content":"'"$NEW_IP"'"}')
    #
    # Check if there was an error with the curl
    #
    if [ $? -eq 0 ]
    then
	#
	# Check the result from the API call
	#
	SUCCESS=`echo $RESULT | grep -Po '"success":\K[^,]*'`
	if [ "$SUCCESS" = "true" ]
        then
            sed -r 's/(^LAST_IP\=)("?)(([0-9]{1,3}\.){3}[0-9]{1,3})("?)/\1\2'"$NEW_IP"'\5/' -i $CONFIG_FILE
	    printf "${GREEN}Updated successfully !!!${STOP}\n"
	else
            printf "${RED}Error while calling the API. Check .conf details.${STOP}\n"
	    echo -n "Error: ${RED}"; echo $RESULT | grep -Po '"errors":\[\K[^\]]*'; echo -n ${STOP}
	    # For a short version use
	    #echo "Messages:"; echo $RESULT | grep -Po '"message":\"\K[^\"]*'
	fi
    else
	printf "${RED}Error while calling curl. Check your connection.${STOP}\n"
    fi
fi
