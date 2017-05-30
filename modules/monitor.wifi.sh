#!/bin/bash
MONITOR[wifi]=0

monitor_wifi_connect_ip(){
  DEBUG "Atempting to get an ip for $WIFIIF $1"
  DEBUG "Retarting dhclient($WIFIIF)"
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
}


monitor_wifi_connect(){
  #Expect $1 to be SSID
  #Expect $2 to be CRYPTO
  #Expect $3 to be FILE
  MONITOR[wifi]=1
  DEBUG "Connecting to $1 with $2"
  INFO "Taking $WIFIIF interface down"
  iw $WIFIIF disconnect
  ifconfig $WIFIIF down
  DEBUG "Getting pid of dhclient"
  DHCLIENT=$(pidof dhclient $WIFIIF)
  if [[ $DHCLIENT != "" ]] ; then
    INFO "Killing dhclient(WIFI)"
    kill $DHCLIENT
  fi
  INFO "Bringing $WIFIIF interface up"
  ifconfig $WIFIIF up
  if [ "$2" = "OPEN" ] || [ "$2" = "LYNX" ] || [ "$2" = "CURL" ]; then
    DEBUG "Attempting to connect to $1"
    local CONNECT=$(iw dev $WIFIIF connect -w $1)
    if [[ $CONNECT == *fail* ]]; then
      MONITOR[wifi]=1
      INFO "Failed to connect to $1"
    else
      AP=$(echo $CONNECT | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
      INFO "Connected to ($AP) $1"
      monitor_wifi_connect_ip
      if [ "$2" = "LYNX" ] ; then
        if [ -s $3 ] ; then
          INFO "Replaying LYNX($3) WIP"
          lynx -cmd_script=$3
        else
          ERROR "Lynx Replay: $3 NOT FOUND"
        fi
      elif [ "$2" = "CURL" ] ; then
        curl -s --max-time 15 $3
      fi
    fi
  elif [ "$2" = "WPA2" ] ; then
    INFO "Connecting to $1 with WPA2"
    #wpa_supplicant -B -c/etc/wpa_supplicant.conf -i $WIFIIF
    ifconfig $WIFIIF down
    iwconfig $WIFIIF mode managed
    ifconfig $WIFIIF up
    iwconfig $WIFIIF essid "$1"
    SLEEP 2
    INFO "Running WPA_SUP"
    wpa_supplicant -B -i$WIFIIF -c/etc/wpa_supplicant.conf
    monitor_wifi_connect_ip
  elif [ "$2" = "WEP"] ; then
    ERROR "WEP Still Untested"
    ifconfig $WIFIIF down
    sleep 1
    ifconfig $WIFIIF up
    iwconfig $WIFIIF essid "$1"
    iwconfig $WIFIIF key $3
    iwconfig $WIFIIF enc on
    monitor_wifi_connect_ip
  else
    ERROR "Don't know how to use $2 Crypto"
  fi
}
monitor_wifi_scan(){
  unset wlanlist
  declare -A wlanlist
  killall wpa_supplicant
  x=0
  ifconfig $WIFIIF up
  for line in $(iwlist $WIFIIF scan | grep ESSID: | cut -d":" -f 2); do
    line=${line%\"}
    line=${line#\"}
    wlanlist[$x]=$line
    x=$[$x + 1]
  done
  wifiscanerror=1
  for i in "${wlanlist[@]}"; do
    if [[ -n ${KNOWNNETS[$i]} ]]; then
      DEBUG "$i is a known network"
      wifimethod=${KNOWNNETS[$i]%:*}
      wifiextra=${KNOWNNETS[$i]#*:}
      if [ "$wifimethod" = "OPEN" ]; then
        INFO "$i Has No Captive Portal"
        wifiscanerror=0
        monitor_wifi_connect $i $wifimethod $wifiextra
        break
      elif [ "$wifimethod" = "WPA2" ]; then
        INFO "$i Requires WPA2"
        wifiscanerror=0
        monitor_wifi_connect $i $wifimethod $wifiextra
        break
      elif [ "$wifimethod" = "WEP" ]; then
        INFO "$i Requires WEP"
        wifiscanerror=0
        monitor_wifi_connect $i $wifimethod $wifiextra
        break
      elif [ "$wifimethod" = "LYNX" ]; then
        INFO "$i Requires LYNX"
        if [ -f $wifiextra ] ; then
          DEBUG "File Exists - RUN LYNX SCRIPT"
          wifiscanerror=0
          monitor_wifi_connect $i $wifimethod $wifiextra
          break
        else
          ERROR "The LYNX file is not found not going to Connect to $i"
        fi
      else
        ERROR "No Connection Method Found for $i"
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
      ifconfig $WIFIIF up
      #NO INTERNET
      DEBUG "System has no internet"
      DEBUG "checking if $WIFIIF is present"
      if [ -d /sys/class/net/$WIFIIF ] ; then
        MONITOR[wifi]=2
        DEBUG "$WIFIIF is installed in the system"
        INFO "Scanning for WiFi on $WIFIIF"
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
