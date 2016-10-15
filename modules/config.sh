#!/bin/bash
check_config(){
  local parse=$(cat "$SELFDIR/extra.sh" | grep "$1=")
  if [ -z "$parse" ] ; then
    local val
    echo "$1 is for $2"
    echo "What Value do you want for $1"
    read val
    echo "$1=\"$val\"			#$2" >> $SELFDIR/extra.sh
  else
    echo "$1 is already in the config"
  fi
}
