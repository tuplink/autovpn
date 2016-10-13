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
TORRENTUSER=""					#rTorrent User
TORRENTPORT=""					#rTorrent port
ENABLEDHT=""					#torrent DHT 1 yes 2 no
SCREENNAME=""            			#Screen session name for rtorrent to run in
MOUNTCHECK=""			     		#Storage Device
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
declare -A MONITOR
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
  # PROGRAM MONITORING
  monitor
  #Check Messages
  reply_msg
  # DYNAMIC DNS
  dynamic_dns
  ## Port Forwarding ##
  forward
  status
done

exit 0
