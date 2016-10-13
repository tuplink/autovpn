#!/bin/bash
MONITOR[VPN Internet]=0
MONITOR[Public Internet]=0
monitor_internet(){
  if [ -n $TORRENTUSER ] ; then
    if echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1 ; then
      DEBUG "Local internet connected"
      MONITOR[Public Internet]=3
    else
      DEBUG "Local internet not connected"
      MONITOR[Public Internet]=1
      MONITOR[VPN Internet]=1
    fi
    if [ "${MONITOR[Public Internet]}" -ge 2 ] && [ "${MONITOR[vpn]}" -ge 2 ] && su $TORRENTUSER -c 'echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1' ; then
      DEBUG "VPN internet connected"
      MONITOR[VPN Internet]=3
    else
      DEBUG "VPN internet not connected"
      MONITOR[VPN Internet]=1
    fi
  fi
  status
}
if [ "$1" == "help" ] ; then
  echo "Must set TORRENTUSER= in Config"
fi


