#!/bin/bash
MONITOR[wifi]=0

#to extra.sh
declare -A KNOWNNETS
KNOWNNETS[AndroidAP]="OPEN"
KNOWNNETS[xfinitywifi]="xfinitywifi.lynx"
KNOWNNETS[Olive]="xfinitywifi.lynx"

monitor_wifi_connect(){
  #Expect $1 to be SSID
  MONITOR[wifi]=1
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
  DEBUG "Attempting to connect to $1"
  local CONNECT=$(iw dev $WIFIIF connect -w $1)
  if [[ $CONNECT == *fail* ]]; then
    MONITOR[wifi]=1
    INFO "Failed to connect to $1"
  else
    AP=$(echo $CONNECT | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
    INFO "Connected to ($AP) $1"
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
}
monitor_wifi_scan(){
  unset wlanlist
  declare -A wlanlist
  x=0
  for line in $(iwlist wlan0 scan | grep ESSID: | cut -d":" -f 2); do
    line=${line%\"}
    line=${line#\"}
    wlanlist[$x]=$line
    x=$[$x + 1]
  done
  wifiscanerror=1
  for i in "${wlanlist[@]}"; do
    if [[ -n ${KNOWNNETS[$i]} ]]; then
      DEBUG "$i is a known network"
      if [ "${KNOWNNETS[$i]}" = "OPEN" ]; then
        INFO "$i Has No Captive Portal"
        wifiscanerror=0
        monitor_wifi_connect $i
        break
      else
        if [ -f ${KNOWNNETS[$i]} ] ; then
          DEBUG "File Exists - RUN LYNX SCRIPT"
          monitor_wifi_connect $i
          wifiscanerror=0
          break
        else
          ERROR "The LYNX file is not found not going to Connect to $i"
        fi
      fi
    fi
    if [ $wifiscanerror -eq "1" ] ; then
      INFO "No Known WIFI To Connect to"
    fi
  done
}


monitor_wifi(){
  if [ -n $WIFIIF ]; then
    if [ "${MONITOR[Public Internet]}" -le 1 ] ; then
      #NO INTERNET
      DEBUG "System has no internet"
      DEBUG "checking if $WIFIIF is present"
      if [ -d /sys/class/net/$WIFIIF ] ; then
        MONITOR[wifi]=2
        DEBUG "$WIFIIF is installed in the system"
        monitor_wifi_scan
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
  fi
}
