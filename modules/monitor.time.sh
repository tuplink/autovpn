#!/bin/bash
monitor_time(){
  if [ ${MONITOR[Public Internet]} -ge 3 ] ; then
    if [ "$NTPSTATUS" != $(date +%H) ] ; then
      INFO "Updating Time"
      if ntpdate time.nist.gov  ; then
        INFO "NTP Time Updated"
        NTPSTATUS=$(date +%H)
      else
        ERROR "NTP Time Update Failed"
      fi
    fi
  fi
}
