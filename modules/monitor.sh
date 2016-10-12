#!/bin/bash
monitor(){
  if [ -n "$(declare -f -F monitor_internet)" ] ; then
    monitor_internet
  fi
  if [ -n "$(declare -f -F monitor_mount)" ] ; then
    monitor_mount
  fi
  if [ -n "$(declare -f -F monitor_rtorrent)" ] ; then
    monitor_rtorrent
  fi
  if [ -n "$(declare -f -F monitor_ads)" ] ; then
    monitor_ads
  fi
  ## IF ALL Monitors are good then sleep for 15
  for key in "${!MONITOR[@]}" ; do
    if [ "${MONITOR[$key]}" -ne 3 ] ; then
      local longsleep=no
    fi
  done
  if [ "$longsleep" != "no" ] ; then
    INFO "All services up taking a nap"
    SLEEP 15
  fi
}

