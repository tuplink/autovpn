monitor_ads(){
  if [ -n $ADSCRIPT ] ; then
    DEBUG "Check ad lists"
    if [ "$ADS" != $(date +%j) ] ; then
      ADS=$(date +%j)
      INFO "Building AD Blocks"
      /bin/bash $ADSCRIPT > /dev/null 2>&1 &
      MONITOR[ad]=2
    else
      #No need to run
      MONITOR[ad]=3
    fi
  else
    INFO "ADSCRIPT not set"
    MONITOR[ad]=1
  fi
}

if [ "$1" == "help" ] ; then
  echo "Must set ADSCRIPT= in Config"
fi

