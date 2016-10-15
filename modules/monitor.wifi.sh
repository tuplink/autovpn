#!/bin/bash
MONITOR[wifi]=0
monitor_wifi(){
  if [ -n $WIFIIF ] && [ -n $WIFISSID ]; then
    if [ "${MONITOR[Public Internet]}" -le 1 ] ; then
      #NO INTERNET
      DEBUG "System has no internet"
      DEBUG "checking if $WIFIIF is present"
      if [ -d /sys/class/net/$WIFIIF ] ; then
        MONITOR[wifi]=2
        DEBUG "$WIFIIF is installed in the system"
        INFO "Taking $WIFIIF interface down"
        iw $WIFIIF disconnect
        ifconfig $WIFIIF down
        DEBUG "Getting pid of dhclient"
        DHCLIENT=$(pidof dhclient $WIFIIF)
        if [[ $DHCLIENT != "" ]] ; then
          INFO "Killing dhclient"
          kill $DHCLIENT
        fi
        INFO "Bringing $WIFIIF interface up"
        ifconfig $WIFIIF up
        DEBUG "Attempting to connect to $WIFISSID"
        local CONNECT=$(iw dev $WIFIIF connect -w $WIFISSID)
        if [[ $CONNECT == *fail* ]]; then
          MONITOR[wifi]=1
          INFO "Failed to connect to $WIFISSID"
        else
          AP=$(echo $CONNECT | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
          INFO "Connected to ($AP) $WIFISSID"
          DEBUG "Starting dhclient"
          dhclient $WIFIIF -nw
          SLEEP 5
          if [[ $(ifconfig $WIFIIF 2>/dev/null | awk '/inet addr/{print substr($2,6)}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$  ]] ; then
            MONITOR[wifi]=3
            INFO "IP Recived for $WIFIIF"
            monitor_internet
          else
            MONITOR[wifi]=1
            INFO "No IP Recived for $WIFIIF"
          fi
        fi
      else
        MONITOR[wifi]=0
        ERROR "$WIFIIF not installed"
      fi
    else
      DEBUG "Internet is already up"
    fi
    status
  else
    ERROR "WIFIIF Not set in config"
    check_config "WIFIIF" "Interface of public wifi (wlan0)"
    check_config "WIFISSID" "SSID of wifi to connect to"
  fi
}
