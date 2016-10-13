#!/bin/bash
status_msg(){
  local msg=""
  for key in "${!MONITOR[@]}" ; do
    local string=$(status_lookup "$key")
    msg+="$key is $string\n"
  done
  INFO "Sending status message"
  send_msg "$msg"
}
if [ "$1" == "help" ] ; then
  echo "No aditional config required"
fi

