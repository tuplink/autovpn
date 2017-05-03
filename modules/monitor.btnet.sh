#!/bin/bash
MONITOR[btnet]=0
monitor_btnet(){
  if [ "${MONITOR[Public Internet]}" -le 1 ] ; then
    #NO INTERNET
    DEBUG "System has no internet"
    DEBUG "checking if bnep0 is present"
    if [ -d /sys/class/net/bnep0 ] ; then
      MONITOR[btnet]=2
      DEBUG "bnep0 is installed in the system"
      DEBUG "Getting pid of dhclient"
      DHCLIENT=$(pidof dhclient bnep0)
      if [[ $DHCLIENT != "" ]] ; then
        INFO "Killing dhclient"
        kill $DHCLIENT
      fi
      DEBUG "Starting dhclient"
      dhclient bnep0 -nw
      SLEEP 5
      if [[ $(ifconfig bnep0 2>/dev/null | awk '/inet addr/{print substr($2,6)}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$  ]] ; then
        MONITOR[btnet]=3
        INFO "IP Recived for bnep0"
        monitor_internet
      else
        MONITOR[btnet]=1
        INFO "No IP Recived for bnep0"
      fi
    else
      MONITOR[btnet]=0
      ERROR "benp0 not installed"
    fi
  else
    DEBUG "Internet is already up"
  fi
  status

}
