#!/bin/bash
## rPi - v1.0 Function:
# -Connect to VPN -Set hostname entry to VPN IP
## -Start rTorrent
## -Start a reverse ssh tunnle -Act as router(VPN or LAN)
## Installation: Add a new hostname ($HOST) in your hosts file
## ($HOSTFILE) (e.g. echo "10.0.0.1 vpniphost" >> /etc/hosts)
## Add bind settings to .rtorrent.rc:
## bind = vpniphost
## schedule = bind_tick,30,30,bind=vpniphost
## portrange = 57225-57225
## add "200 ubuntu" to the end of /etc/iproute2/rt_tables
##
## $VPNCF must contain (daemon) and (auth-user-pass PASSWORD FILE) Options and all filenames must be
## full paths PASSWORD FILE is 2 lines username and password
##STATTIC STUFF
SELF=${BASH_SOURCE[0]}
SELFDIR="$( cd "$( dirname "$SELF" )" && pwd )"
##
#####SET DEFAULTS####
LOCKFILE="$SELFDIR/vpn.pid"			#Script lock
DISPLAYSHOW="14"                                #Log entrys to show
LOGLEVEL="2"                                    #1 ERROR 2 INFO 3 DEBUG
SCRIPT_LOG=/dev/null                            #path to log to
#VPN
VPNIF=""	                                #VPN IF
VPNCF=""					#VPN config File
VPNROUTE=""					#VPN route script
VPNPASS=""					#VPN Password
HOSTFILE="/etc/hosts"				#hostname file
HOST="vpniphost"				#hostname for local lookups
#AD BLOCKING
ADSCRIPT="$SELFDIR/pihole/gravity.sh"		#PiHole Script
#RTORRENT
TORRENTUSER="ubuntu"				#rTorrent User
TORRENTPORT="57225"				#rTorrent port
ENABLEDHT="1"					#torrent DHT 1 yes 2 no
SCREENNAME="torrent"            		#Screen session name for rtorrent to run in
MOUNTCHECK="/media/torrent"     		#Storage Device
#REVERSE TUNNEL ACCESS
SSHKEY=""					#tunnle key
SSHHOST=""					#tunnle host
SSHREMOTEUSER=""				#tunnle user
SSHLOCALPORT=""					#internal port for tunnle
SSHREMOTEPORT=""				#external port for tunnle
#ROUTING STUFF
APIF="wlan9"					#Hotspot Interface
LANIF="eth0"					#LAN Interface
APTOVPN="1"					#1 Hotspot over vpn 0 Hotspot over internet
#AUTO CONNECT TO OPEN WIFI
WIFIIF="wlan0"					#wifi for connecting to open wifi
WIFISSID="xfinitywifi"				#SSID to connect to
#DYNAMIC DNS (DUCKDNS)
DUCKKEY=""					#DUCKDNS Key
DUCKDOMAIN=""					#DUCKDNS DOMAIN (bob.duckdns.org)
#Messaging
PBKEY=""                                        #Pushbullet key

##########DO NOT EDIT BELOW THIS LINE##################
declare -A GPIOPINOUT
RUNOPTS=$@
#/Settings
if [[ -r extra.sh ]] ; then
  source extra.sh
fi
#/Settings

#/MODULES
for f in $SELFDIR/modules/*.sh; do
  source $f
done
#/MODULES

######################START OF SCRIPT#########################
#GET SCRIPT OPTIONS
while [ "`echo $1 | cut -c1`" = "-" ]; do
  case "$1" in
    "--quiet"|"-q"           ) QUIET=1;shift 1;;
    "--force"|"-f"           ) FORCE=1;shift 1;;
    "--enable"               ) if [ -a "$SELFDIR/modules/$2.shx" ] ; then
                                  echo "Enabling $2"
                                  mv $SELFDIR/modules/$2.shx $SELFDIR/modules/$2.sh
                                  $SELFDIR/modules/$2.sh help
                                  exit 1
                               elif [ -a "$SELFDIR/modules/$2.sh" ] ; then
                                 echo "Module already enabled"
                                 exit 0
                               else
                                 echo "$2 not avaliable"
                                 exit
                               fi;;
    "--disable"              ) if [ -a "$SELFDIR/modules/$2.sh" ] ; then
                                 echo "Disabling $2"
                                 mv $SELFDIR/modules/$2.sh $SELFDIR/modules/$2.shx
                                 exit 1
                               elif [ -a "$SELFDIR/modules/$2.shx" ] ; then
                                 echo "Module already disabled"
                                 exit 0
                               else
                                 echo "$2 not avaliable"
                                 exit 0
                               fi;;
    "--list"                ) echo "Enabled"
                              for f in $SELFDIR/modules/*.*.sh; do
                                echo "  "$(basename "${f%.*}")
                              done
                              echo "Available"
                              for f in $SELFDIR/modules/*.*.shx; do
                                echo "  "$(basename "${f%.*}")
                              done
                              exit 1;;
    *                       ) echo "ERROR: Invalid option: \""$1"\""; exit 1;;
  esac
done


##CHECK IF USER IS ROOT
if [[ $EUID -ne 0 ]];then
  if [ -x "$(command -v sudo)" ];then
    echo "Switching to root"
    sudo $SELF $RUNOPTS
    exit 1
  else
    echo "Please install sudo or run this script as root."
    exit 1
  fi
fi


HOSTNAME=$(hostname)
UPTIME=$(uptime | sed -E 's/^[^,]*up *//; s/, *[[:digit:]]* users.*//; s/min/minutes/; s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/')
## LOGGING FUNCTIONS
touch $SCRIPT_LOG
if [ "$LOGLEVEL" == "1" ] ; then
  ERRORLOG=1
  INFOLOG=0
  DEBUG=0
elif [ "$LOGLEVEL" == "2" ] ; then
  ERRORLOG=1
  INFOLOG=1
  DEBUG=0
else
  ERRORLOG=1
  INFOLOG=1
  DEBUGLOG=1
fi

##CHECK IF RUNNING ALREADY
if [ -e $LOCKFILE ]; then
  # A lockfile exists... Lets check to see if it is still valid
  PID=`cat $LOCKFILE`
  if [ -e /proc/$PID ] ; then
    if [[ "$FORCE" == "1" ]] ; then
      INFO "Killed running script"
      kill -9 $PID
    else
      ERROR "Script still running, Restart wirh -f"
      exit 1
    fi
  fi
fi

## SCRIPT LOCK
echo $$ > $LOCKFILE
while true; do
  ## Add OPTIONS ##
  read -sn1 -t1 c
  case $c in
    1) SYSTEM "Restarted VPN script"; $SELF -f $RUNOPTS;;
    2) SYSTEM "Restarted OpenVPN"; killall openvpn;;
    3) SYSTEM "Restarted SSH tunnel"; killall ssh;;
    4) SYSTEM "Restarted rTorrent"; killall screen;;
    5) SYSTEM "Logging set to DEBUG" ; LOGLEVEL=9 ; ERRORLOG=1 ; INFOLOG=1 ; DEBUGLOG=1;;
    6) SYSTEM "Logging set to INFO" ; LOGLEVEL=2 ; ERRORLOG=1 ; INFOLOG=1 ; DEBUG=0;;
    7) SYSTEM "Logging set to ERROR" ; LOGLEVEL=1 ; ERRORLOG=1 ; INFOLOG=0 ; DEBUG=0 ;;
    9) SYSTEM "Updating Ad Host" ; ADS=0;;
    [Xx]) SYSTEM "Exiting VPN script..." ; exit;;
    [Ii]) INFO "Incresing log"; DISPLAYSHOW=$[$DISPLAYSHOW+2];;
    [Dd]) INFO "Decreasing Log"; DISPLAYSHOW=$[$DISPLAYSHOW-2]
  esac
  ## CHECK OPENVPN ##
  DEBUG "Checking VPN status"
  if [ -f /sys/class/net/$VPNIF/operstate ]; then
    INFO "VPN is active"
    if su $TORRENTUSER -c 'echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 5 google.com 80 > /dev/null 2>&1' ; then
      MONITOR[vpn]=3
      DEBUG "VPN has internet"
      #Check Messages
      reply_msg
      # DYNAMIC DNS
      dynamic_dns
      ## Port Forwarding ##
      forward
      # PROGRAM MONITORING
      monitor
      status
      SLEEP 15
    else
      INFO "VPN has no internet"
      ERROR "KILLING OpenVPN"
      killall openvpn
      SLEEP 1
    fi
  else
    INFO "VPN not up"
    MONITOR[vpn]=1
    ## Test Internet Connection
    DEBUG "Testing for internet connection"
    if echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1 ; then
      DEBUG "Internet is good"
#      send_msg "Internet is Connected Starting VPN"
      ## START OPENVPN
      VPNPID=$(pidof openvpn)
      if [ -n "$VPNPID" ]; then
        ERROR "VPN running but no interface yet"
        INFO "Killing OpenVPN process ($VPNPID)"
        kill -9 $VPNPID
      fi
      INFO "Starting VPN"
      MONITOR[vpn]=2
      openvpn --daemon --config "$VPNCF" --writepid "$SELFDIR/openvpn.pid" --auth-user-pass "$VPNPASS" --route-nopull --route-up "$VPNROUTE" --script-security 2
      #WAIT FOR CONNECTION
      SLEEP 15
      VPNIP=$(ifconfig $VPNIF 2>/dev/null | awk '/inet addr/{print substr($2,6)}')
      if [[ -z "$VPNIP" ]]; then
        ERROR "Cannot find IP for $VPNIF."
      else
        # update current VPN IP
        DEBUG "Checking $HOSTFILE for $HOST $VPINIP"
        FINDLINE=$(cat $HOSTFILE | egrep -n "\ $HOST$" | tail -n 1)
        FINDLINENR=$(echo $FINDLINE | egrep -o "[0-9]+:" | egrep -o "[0-9]+")
        FINDOLDIP=$(echo $FINDLINE | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
        if [[ -z "$FINDLINENR" ]] || [[ -z "$FINDOLDIP" ]]; then
          ERROR "Couldn't find '$HOST' host in $HOSTFILE"
          INFO "Adding $HOST to $HOSTFILE"
          echo "$VPNIP    $HOST" >> $HOSTFILE
        else
          # check if IP has changed
          if [[ "$VPNIP" != "$FINDOLDIP" ]]; then
            INFO "Updating hosts file '$HOST' to $VPNIP (old: $FINDOLDIP)"
            sed -i.bak -e "$FINDLINENR s/$FINDOLDIP/$VPNIP/" $HOSTFILE
          else
           INFO "$HOSTFILE up to date"
          fi
        fi
        if [ "$FWSET" != "1" ] ; then
          ## IPTABLE CONFIG ##
          DEBUG "Enabeling IP Forwardig"
          echo 1 > /proc/sys/net/ipv4/ip_forward
          #ASYNC Routing enable
          if [ -z $ASYNC ] ; then
            ASYNC=1
            INFO "Keeping inbound traffic on interface"
            ip rule add from $VPNIP/32 table ubuntu priority 100
          fi
          INFO "Adding IPTABLE RULES"
          iptables -F -t nat
          iptables -F -t mangle
          iptables -F -t filter
          ## User packets marked for VPN
          INFO "Marking packets from $TORRENTUSER"
          iptables -t mangle -A OUTPUT -m owner --gid-owner $TORRENTUSER -j MARK --set-mark 1
          iptables -t mangle -A OUTPUT -m owner --gid-owner $TORRENTUSER -j CONNMARK --save-mark
          ## ADD ROUTER STUFF
          if [ $APTOVPN -eq 1 ] ; then
            INFO "Sendind $APIF traffic over VPN"
            iptables -t mangle -A PREROUTING -i $APIF -j MARK --set-mark 1
            iptables -t mangle -A PREROUTING -i $APIF -j CONNMARK --save-mark
            iptables -A INPUT -i $APIF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -t nat -A POSTROUTING -o $VPNIF -j MASQUERADE
            iptables -A FORWARD -i $APIF -o $VPNIF -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -A FORWARD -i $VPNIF -o $APIF -j ACCEPT
          else
            INFO "Sendind $APIF traffic over LAN"
            iptables -t nat -A POSTROUTING -o $LANIF -j MASQUERADE
            iptables -A FORWARD -i $APIF -o $LANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -A FORWARD -i $LANIF -o $APIF -j ACCEPT
          fi
          # allow responses
          iptables -A INPUT -i $VPNIF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
          # allow incoming $TORRENTPORT
          iptables -A INPUT -i $VPNIF -p tcp --dport $TORRENTPORT -j ACCEPT
          iptables -A INPUT -i $VPNIF -p udp --dport $TORRENTPORT -j ACCEPT
          # allow incoming DHT
          if [[ "$ENABLEDHT" = "1" ]]; then
            INFO "Enabling DHT firewall rule"
            iptables -A INPUT -i $VPNIF -p udp --dport 6881 -j ACCEPT
            iptables -t raw -I PREROUTING -i $VPNIF -p udp --dport 6881 -j NOTRACK
            iptables -t raw -I OUTPUT -o $VPNIF -p udp --sport 6881 -j NOTRACK
          fi
          ## block everything else incoming on $VPNIF
          iptables -A INPUT -i $VPNIF -j DROP
          ## ALLOW ALL $LANIF
          iptables -A INPUT -i $LANIF -j ACCEPT
          iptables -A OUTPUT -o $LANIF -j ACCEPT
          ## ALLOW ALL $APIF
          iptables -A INPUT -i $APIF -j ACCEPT
          iptables -A OUTPUT -o $APIF -j ACCEPT
          # Allow $LANIF Internal DNS
          iptables -t nat -A PREROUTING -p udp --dport 53 -i $LANIF -j DNAT --to 172.24.1.1:53
          FWSET=1
       fi
      fi
    else
      #NO INTERNET
      DEBUG "System has no internet"
      DEBUG "checking if $WIFIIF is present"
      if [ -d /sys/class/net/$WIFIIF ] ; then
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
        CONNECT=$(iw dev $WIFIIF connect -w $WIFISSID)
        if [[ $CONNECT == *fail* ]]; then
          INFO "Failed to connect to $WIFISSID"
        else
          AP=$(echo $CONNECT | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
          INFO "Connected to ($AP) $WIFISSID"
          DEBUG "Starting dhclient"
          dhclient $WIFIIF -nw
          SLEEP 5
          if [[ $(ifconfig $WIFIIF 2>/dev/null | awk '/inet addr/{print substr($2,6)}') =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$  ]] ; then
            INFO "IP Recived for $WIFIIF"
          else
            INFO "No IP Recived for $WIFIIF"
          fi
        fi
      else
        ERROR "$WIFIIF not installed"
        SLEEP 15
      fi
    fi
  fi
done

exit 0
