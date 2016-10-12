#!/bin/bash
MONITOR[VPN Internet]=0
MONITOR[Public Internet]=0
monitor_internet(){
  if [ -n $TORRENTUSER ] ; then
    if echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1 ; then
      MONITOR[Public Internet]=3
    else
      MONITOR[Public Internet]=1
      MONITOR[VPN Internet]=1
    fi
    if [ "${MONITOR[Public Internet]}" -ge 2 ] && [ "${MONITOR[vpn]}" -ge 2 ] && su $TORRENTUSER -c 'echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1' ; then
      MONITOR[VPN Internet]=3
    else
      MONITOR[VPN Internet]=1
    fi
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set TORRENTUSER= in Config"
  echo "Must set SCREENNAME= in Config"
fi


