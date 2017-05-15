#!/bin/bash
MONITOR[wired]=0
monitor_wired(){
  if [ "${MONITOR[Public Internet]}" -le 1 ] ; then
    #NO INTERNET
    DEBUG "System has no internet"
    DEBUG "checking if eth0 is present"
    if [ -d /sys/class/net/eth0 ] ; then
      MONITOR[wired]=2
      DEBUG "eth0 is installed in the system"
      ethlink=$(cat /sys/class/net/eth0/carrier)
      if [ "$ethlink" = "1" ] ; then
        DEBUG "Getting pid of dhclient"
        DHCLIENT=$(pidof dhclient eth0)
        if [[ $DHCLIENT != "" ]] ; then
          INFO "Killing dhclient(Wired)"
          kill $DHCLIENT
        fi
        DEBUG "Starting dhclient"
        dhclient eth0 -nw
        SLEEP 5
        if [[ $(ifconfig eth0 2>/dev/null | awk '/inet addr/{print substr($2,6)}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$  ]] ; then
          MONITOR[wired]=3
          INFO "IP Recived for eth0"
          monitor_internet
        else
          MONITOR[wired]=1
          INFO "No IP Recived for eth0"
        fi
    else
      DEBUG "ETH Calbe not plugged in"
    fi
    else
      MONITOR[wired]=0
      ERROR "eth0 not installed"
    fi
  else
    DEBUG "Internet is already up"
  fi
  status

}
