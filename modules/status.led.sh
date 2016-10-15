#!/bin/bash
# use pins physical pins
# 4 17 27 22 29 31 33 35 37 40 20 16 12 16 18 22 32 26 28 40
#
#SETUP ALL REQUIRED PINS AS OUTPUTS
if [ -e /sys/class/gpio/export ] ; then
  for val in ${GPIOPINOUT[@]} ; do
    if [ "$val" -gt 0 ] ; then
      if [ -e "/sys/class/gpio/gpio$val/value" ] ; then
        echo "$val" > /sys/class/gpio/unexport
        DEBUG "GPIO: unexported $val"
      fi
      echo "$val" > /sys/class/gpio/export
      DEBUG "GPIO: exported $val"
      echo out > /sys/class/gpio/gpio$val/direction
      echo 0 > /sys/class/gpio/gpio$val/value
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
