#!/bin/bash
monitor_time(){
  DEBUG "Checking if we need to Update Time"
  if [ ${MONITOR[Public Internet]} -ge 3 ] ; then
    if [ "$NTPSTATUS" != $(date +%H) ] ; then
      if [[ $(ntpdate time.nist.gov) -ne 0 ]] ; then
        DEBUG "NTP Time Update Failed"
      else
        DEBUG "NTP Time Updated"
        NTPSTATUS=$(date +%H)
      fi
    fi
  fi
}
