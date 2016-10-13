#!/bin/bash
MONITOR[ads]=0
monitor_ads(){
  if [ -n $ADSCRIPT ] ; then
    if [ ${MONITOR[Public Internet]} -ge 3 ] ; then
      DEBUG "Check ad lists"
      if [ "$ADS" != $(date +%j) ] ; then
        ADS=$(date +%j)
        INFO "Building AD Blocks"
        /bin/bash $ADSCRIPT > /dev/null 2>&1 &
        MONITOR[ads]=2
      else
        #No need to run
        MONITOR[ads]=3
      fi
    fi
  else
    INFO "ADSCRIPT not set"
    MONITOR[ads]=1
  fi
  status
}

if [ "$1" == "help" ] ; then
  echo "Must set ADSCRIPT= in Config"
fi
