#!/bin/bash
MONITOR[VPN Internet]=0
MONITOR[Public Internet]=0
monitor_internet(){
  if [ -n $TORRENTUSER ] ; then
    if echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 5 google.com 80 > /dev/null 2>&1 ; then
      DEBUG "Local internet connected"
      MONITOR[Public Internet]=3
      PUBLICIP=$(curl -s --max-time 5 http://api.ipify.org/?format=text)
    else
      DEBUG "Local internet not connected"
      MONITOR[Public Internet]=1
      MONITOR[VPN Internet]=1
    fi
    if [ "${MONITOR[Public Internet]}" -ge 3 ] && [ "${MONITOR[vpn]}" -ge 2 ] && su $TORRENTUSER -c 'echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 5 google.com 80 > /dev/null 2>&1' ; then
      DEBUG "VPN internet connected"
      MONITOR[VPN Internet]=3
      VPNIP=$(su $TORRENTUSER -c "curl -s --max-time 5 http://api.ipify.org/?format=text")
    else
      DEBUG "VPN internet not connected"
      MONITOR[VPN Internet]=1
    fi
  fi
  status
}


