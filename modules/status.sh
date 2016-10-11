#!/bin/bash
status(){
  if [ -n "$(declare -f -F status_print)" ] ; then
    status_print
  fi
  if [ -n "$(declare -f -F status_led)" ] ; then
    status_led
  fi
}

status_lookup(){
  # 0 unknown
  # 1 stopped
  # 2 started
  # 3 running
  if [ "${MONITOR[$1]}" == "1" ] ; then
    echo "stopped"
  elif [ "${MONITOR[$1]}" == "2" ] ; then
    echo "started"
  elif [ "${MONITOR[$1]}" == "3" ] ; then
    echo "running"
  else
    echo "unknown"
  fi
}

