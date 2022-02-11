#!/bin/bash

#
# Automatically update a Gandi DNS A record to your current public IP address using Gandi's LiveDNS API
# 
# Usage: ./gandi-dynamic-dns.sh www.example.com
#

# CHECK: curl is installed
if [ ! command -v curl &> /dev/null ]
then
  echo "curl could not be found"
  exit
fi

# CHECK: jq is installed
if [ ! command -v jq &> /dev/null ]
then
  echo "jq could not be found"
  exit
fi

# CHECK: FQDN argument is present
if [ -z "$1" ]
then
  echo "Fully qualified domain name not present"
  exit 1
fi

# CHECK: valid FQDN is submitted
if [ -z $(echo $1 | grep -P '(?=^.{1,254}$)(^(?>(?!\d+\.)[a-zA-Z0-9_\-]{1,63}\.?)+(?:[a-zA-Z]{2,})$)') ]
then
  echo "Invalid fully qualified domain name"
  exit 1
fi

# SET: required information
API_KEY=$(cat $(dirname $0)/api_key.secret)
HOST=$(echo $1 | cut -d"." -f1)
DOMAIN=$(echo $1 | cut -d"." -f1 --complement)
GET_IP_WEBSITE="https://ifconfig.co/"

# FUNCTION: check for a valid ip address
function valid_ip()
{
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
  then
      OIFS=$IFS
      IFS='.'
      ip=($ip)
      IFS=$OIFS
      [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
          && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
      stat=$?
  fi
  return $stat
}

# Get current IP address
if valid_ip $(curl -s -4 $GET_IP_WEBSITE)
then
  IP_NOW=$(curl -s -4 $GET_IP_WEBSITE)
else
  # Exiting due to invalid IP address
  echo "Invalid IP address from $GET_IP_WEBSITE"
  exit 1
fi

# Get Gandi DNS IP address
if valid_ip $(curl -s -H "Authorization: Apikey $API_KEY" -X GET https://api.gandi.net/v5/livedns/domains/$DOMAIN/records/$HOST/A | jq -r '.rrset_values[0]')
then
  IP_GANDI=$(curl -s -H "Authorization: Apikey $API_KEY" -X GET https://api.gandi.net/v5/livedns/domains/$DOMAIN/records/$HOST/A | jq -r '.rrset_values[0]')
else
  # Exiting due to invalid IP address
  echo "Invalid IP address from Gandi API"
  exit 1
fi

# Check if the IP addresses match and change DNS entry if the don't
if [ $IP_NOW == $IP_GANDI ]
then
  # They are the same, exiting
  echo "No update required"
  exit 0
else
  curl -s -H "Authorization: Apikey $API_KEY" -H "Content-Type: application/json" -d '{"rrset_values": ["'${IP_NOW}'"], "rrset_ttl": 1800}' -X PUT https://api.gandi.net/v5/livedns/domains/"${DOMAIN}"/records/"${HOST}"/A > /dev/null
  if [ "$?" -ne 0 ]
  then
    echo "There was a problem running the LiveDNS update command"
    exit 1
  else
    echo "DNS record updated"
  fi
fi