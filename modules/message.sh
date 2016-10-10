#!/bin/bash
send_msg(){
  if [ -n "$(declare -f -F telegram_send)" ] ; then
    telegram_send "$@"
  elif [ -n "$(declare -f -F pushbullet_send)" ] ; then
    pushbullet_send "$@"
  else
    echo "No way to send message $@"
  fi


}

