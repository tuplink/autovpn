#!/bin/bash
pushbullet_send(){
  if [ -n $PBKEY ] ; then
    curl -o /dev/null -s -u $PBKEY: https://api.pushbullet.com/v2/pushes -d type=note --data-urlencode "body=$1"
  else
    ERROR "PBKEY not set"
    check_config "PBKEY" "Pushbullet API key"
  fi
}
