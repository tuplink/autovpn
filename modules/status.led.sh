#!/bin/bash

#SETUP ALL REQUIRED PINS AS OUTPUTS
if [ -e /sys/class/gpio/export ] ; then
  for val in $GPIOPINOUT ; do
    if [ "$val" -gt 0 ] ; then
      echo "$val" > /sys/class/gpio/export
      echo out > /sys/class/gpio/gpio$val/direction
    fi
  done
fi

status_led(){
  if [ -e /sys/class/gpio/export ];then
    for key in "${!GPIOPINOUT[@]}" ; do
      local gpio="${GPIOPINOUT[$key]}"
      if [ "${MONITOR[$key]}" -ge 3 ] ; then
        #STATUS IS GOOD
        echo 1 > /sys/class/gpio/gpio$gpio/value
      else
        echo 0 > /sys/class/gpio/gpio$gpio/value
      fi
    done
  fi
}

if [ "$1" == "help" ] ; then
  echo "GPIO /sys/class/gpio/export is required to use this module"
  echo "add GPIOPINOUT['SERVICE']=11 to extras"
fi

