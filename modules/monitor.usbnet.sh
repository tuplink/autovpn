#!/bin/bash
MONITOR[usbnet]=0
monitor_usbnet(){
  if [ "${MONITOR[Public Internet]}" -le 1 ] ; then
    #NO INTERNET
    DEBUG "System has no internet"
    DEBUG "checking if usb0 is present"
    if [ -d /sys/class/net/usb0 ] ; then
      MONITOR[usbnet]=2
      DEBUG "usb0 is installed in the system"
      DEBUG "Getting pid of dhclient"
      DHCLIENT=$(pidof dhclient usb0)
      if [[ $DHCLIENT != "" ]] ; then
        INFO "Killing dhclient"
        kill $DHCLIENT
      fi
      DEBUG "Starting dhclient"
      dhclient usb0 -nw
      SLEEP 5
      if [[ $(ifconfig usb0 2>/dev/null | awk '/inet addr/{print substr($2,6)}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$  ]] ; then
        MONITOR[usbnet]=3
        INFO "IP Recived for usb0"
        monitor_internet
      else
        MONITOR[usbnet]=1
        INFO "No IP Recived for usb0"
      fi
    else
      MONITOR[usbnet]=0
      ERROR "usb0 not installed"
    fi
  else
    DEBUG "Internet is already up"
  fi
  status

}
