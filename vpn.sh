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
#Settings
LOCKFILE="$SELFDIR/vpn.pid"			#Script lock
VPNIF="tun0"					#VPN interface
VPNCF="$SELFDIR/openvpn/PIA/CA Montreal.ovpn"	#VPN config File
VPNROUTE="$SELFDIR/openvpn/vpn-route"		#VPN route script
VPNPASS="$SELFDIR/openvpn/user.txt"		#VPN Password
HOSTFILE="/etc/hosts"				#hostname file
HOST="vpniphost"				#hostname for local lookups
ADSCRIPT="$SELFDIR/pihole/gravity.sh"		#PiHole Script
TORRENTUSER="ubuntu"				#rTorrent User
TORRENTPORT="57225"				#rTorrent port
ENABLEDHT="1"					#torrent DHT 1 yes 2 no
SCREENNAME="torrent"            		#Screen session name for rtorrent to run in
MOUNTCHECK="/media/torrent"     		#Storage Device
SSHKEY=""					#tunnle key
SSHHOST=""					#tunnle host
SSHREMOTEUSER=""				#tunnle user
SSHLOCALPORT="80"				#internal port for tunnle
SSHREMOTEPORT="19999"				#external port for tunnle
APIF="wlan9"					#Hotspot Interface
LANIF="eth0"					#LAN Interface
APTOVPN="1"					#1 Hotspot over vpn 0 Hotspot over internet
WIFIIF="ra0"					#wifi for connecting to open wifi
WIFISSID="xfinitywifi"				#SSID to connect to
DISPLAYSHOW="14"				#Log entrys to show
LOGLEVEL="2"					#1 ERROR 2 INFO 3 DEBUG
SCRIPT_LOG=/dev/null				#path to log to
#/Settings
if [[ -r extra.sh ]] ; then
  source extra.sh
fi
#/Settings
HOSTNAME=$(hostname)
UPTIME=$(uptime | sed -E 's/^[^,]*up *//; s/, *[[:digit:]]* users.*//; s/min/minutes/; s/([[:digit:]]+):0?([[:digit:]]+)/\1 hours, \2 minutes/')
## LOGGING FUNCTIONS
touch $SCRIPT_LOG
if [ "$LOGLEVEL" == "1" ] ; then
  echo "LOGGING set to ERROR"
  ERRORLOG=1
  INFOLOG=0
  DEBUG=0
elif [ "$LOGLEVEL" == "2" ] ; then
  echo "LOGGING set to INFO"
  ERRORLOG=1
  INFOLOG=1
  DEBUG=0
else
  echo "LOGGING set to DEBUG"
  ERRORLOG=1
  INFOLOG=1
  DEBUGLOG=1
fi

function DISPLAY(){
  clear
  local NEW="$1"
  if [ "$NEW" != "" ] ; then
    MSG[0]=${MSG[1]}
    MSG[1]=${MSG[2]}
    MSG[2]=${MSG[3]}
    MSG[3]=${MSG[4]}
    MSG[4]=${MSG[5]}
    MSG[5]=${MSG[6]}
    MSG[6]=${MSG[7]}
    MSG[7]=${MSG[8]}
    MSG[8]=${MSG[9]}
    MSG[9]=${MSG[10]}
    MSG[10]=${MSG[11]}
    MSG[11]=${MSG[12]}
    MSG[12]=${MSG[13]}
    MSG[13]=${MSG[14]}
    MSG[14]=${MSG[15]}
    MSG[15]=${MSG[16]}
    MSG[16]=${MSG[17]}
    MSG[17]=${MSG[18]}
    MSG[18]=${MSG[19]}
    MSG[19]=${MSG[20]}
    MSG[20]=$NEW
  fi
  COLS=$(tput cols)
  HALFCOLS=$[$COLS/2]
  HR
  CENTERTEXT "$USER@$HOSTNAME:$SELFPWD/$SELF"
  HR
  echo "1) Restart VPN Script     6) Set INFO loggging"
  echo "2) Restart OpenVPN        7) Set ERROR loggging"
  echo "3) Restart SSH Tunnel     8)"
  echo "4) Restart rTorrent       9) Update Ad Hosts"
  echo "5) Set DEBUG loggging     x) Exit"
  echo "i) Increse log            d) Decrese Log"
  HR
  CENTERTEXT "Logging set to $LOGLEVEL  Uptime: $UPTIME"
  CENTERTEXT "Forwarded Port: $PORT"
  HR
  CENTERTEXT "LOG($DISPLAYSHOW) $SLEEPMSG"
  HR
  DISPLAYNUM=${#MSG[@]}
  DISPLAYSTART=$[$DISPLAYNUM-$DISPLAYSHOW]
  printf '%s\n' "${MSG[@]:$DISPLAYSTART:$DISPLAYSHOW}"
  echo "Please select and option"
}

SLEEP(){
#  DEBUG "Taking a $1 second nap"
  while [ $sleep -lt $1 ] ; do
    sleep 1
    DISPLAY
    sleep=$[$sleep+1]
    SLEEPREM=$[$1-$sleep]
    SLEEPMSG=" - Taking a $SLEEPREM second nap"
    if [ "$SLEEPREM" == "0" ] ; then
      SLEEPMSG=""
    fi
  done
  sleep=0
}

SYSTEM(){
  local function_name="${FUNCNAME[1]}"
  local msg="$1"
  timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
  DISPLAY "$(tput setaf 5)[$timeAndDate] [SYSTEM] $msg$(tput setaf 7)"
  echo "[$timeAndDate] [SYSTEM] $msg" > $SCRIPT_LOG
  logger"[$timeAndDate] [VPN.sh] $msg"
}

ERROR(){
 if [ "$ERRORLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "$(tput setaf 1)[$timeAndDate] [ERROR]  $msg$(tput setaf 7)"
    echo "[$timeAndDate] [ERROR]  $msg" > $SCRIPT_LOG
  fi
}
INFO(){
  if [ "$INFOLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "$(tput setaf 7)[$timeAndDate] [INFO]   $msg$(tput setaf 7)"
    echo "[$timeAndDate] [INFO]   $msg" >> $SCRIPT_LOG
  fi
}
DEBUG(){
  if [ "$DEBUGLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "$(tput setaf 3)[$timeAndDate] [DEBUG]  $msg$(tput setaf 7)"
    echo "[$timeAndDate] [DEBUG]  $msg" >> $SCRIPT_LOG
  fi
}

HR(){
  COLS=$(tput cols)
  printf "%0*d\n" "$COLS"
}

CENTERTEXT(){
  COLS=$(tput cols)
  LENGTH=${#1}
  CENTER=$(expr $COLS / 2)
  HALFSTRING=$(expr $LENGTH / 2 )
  PAD=$(expr $CENTER + $HALFSTRING)
  printf "%${PAD}s\n" "$1"
}


##CHECK IF USER IS ROOT
if [[ $EUID -eq 0 ]];then
	INFO "User is ROOT"
else
	if [ -x "$(command -v sudo)" ];then
                INFO "Switching to root"
                sudo su -c "$SELF -f"
		exit 1
	else
		ERROR "Please install sudo or run this script as root."
		exit 1
	fi
fi
##CHECK IF RUNNING ALREADY
if [ -e $LOCKFILE ]; then
  # A lockfile exists... Lets check to see if it is still valid
  PID=`cat $LOCKFILE`
  if [ -e /proc/$PID ] ; then
    if [[ $1 = "-f" ]] ; then
      INFO "Killed running script"
      kill -9 $PID
    else
      ERROR "Script still running, Restart wirh -f"
      exit 1
    fi
  fi
fi
#STATIC VAR#
#FWSET=0



## SCRIPT LOCK
echo $$ > $LOCKFILE
while true; do
  ## Add OPTIONS ##
  read -sn1 -t1 c
  case $c in
    1) SYSTEM "Restarted VPN script"; $SELF -f;;
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
  ## CHECK MOUNT ##
  if [[ ! -z "$MOUNTCHECK" ]]; then
    DEBUG "Checking if $MOUNTCHECK is mounted"
    testmount=$(/bin/mount | grep "on $MOUNTCHECK")
    if [[ -z "$testmount" ]]; then
      INFO "Mounting $MOUNTCHECK"
      mount $MOUNTCHECK
    else
      DEBUG "$MOUNTCHECK is Mounted"
    fi
  fi
  ## CHECK OPENVPN ##
  DEBUG "Checking VPN status"
  if [ -f /sys/class/net/$VPNIF/operstate ]; then
    INFO "VPN is active"
    if su ubuntu -c 'echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1' ; then
      DEBUG "VPN has internet"
      DEBUG "Check ad lists"
      if [ "$ADS" != $(date +%j) ] ; then
        ADS=$(date +%j)
        INFO "Building AD Blocks"
        /bin/bash $ADSCRIPT > /dev/null 2>&1 &
      fi
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
      fi
      ##  SSH TUNNEL ##
      DEBUG "Checking status of Reverse Tunnel"
      SSHPID=$(pgrep -f 'ssh -o ConnectTimeout=10')
      if [ -z "$SSHPID" ]; then
        INFO "Starting SSH Tunnel"
        if ssh -o ConnectTimeout=10 -o ExitOnForwardFailure=yes -fN -i $SSHKEY $SSHREMOTEUSER@$SSHHOST -R $SSHREMOTEPORT:*:$SSHLOCALPORT  > /dev/null 2>&1; then
          INFO "SSH tunnel established"
        else
          ERROR "SSH tunnel failed"
        fi
      else
        DEBUG "Reverse tunnel is up"
      fi
      ## PIA Port forward every hour
      DEBUG "Checking if we need to run port forward script"
      if [ "$PORTFOR" != $(date +%H) ] ; then
        OLDPORT=$PORT
        PORT=$($SELFDIR/portforward/port_forward.sh -f $VPNPASS -i $VPNIF -s)
        PORTFOR=$(date +%H)
        if [[ $PORT =~ ^-?[0-9]+$ ]] ; then
          INFO "Inbound port is $PORT"
          if [ "$OLDPORT" != "$PORT"] ; then
            INFO "Port Number changed"
            ETHIP=$(ifconfig $LANIF | awk '/inet / {print $2}' | awk 'BEGIN { FS = ":" } {print $(NF)}')
            DEBUG "Adding new rule for inbound port"
            iptables -t nat -A PREROUTING -p tcp --dport $PORT -i $LANIF -j DNAT --to $ETHIP:80
          fi
        else
          INFO "Port not valid"
        fi
      fi
      ##  RTORRENT CHECK ##
      DEBUG "Check if rtrrent is up"
      TESTSCREEN=$(su $TORRENTUSER -c 'screen -ls | egrep "[0-9]+.$SCREENNAME"')
      if [[ -n "$TESTSCREEN" ]]; then
        INFO "rTorrent is running."
      else
        INFO "Starting rTorrent"
        stty stop undef 2>/dev/null
        stty start undef 2>/dev/null
        su $TORRENTUSER -c "screen -A -dmS $SCREENNAME /usr/local/bin/rtorrent"
      fi
      SLEEP 15
    else
      INFO "VPN has no internet"
      ERROR "KILLING OpenVPN"
      killall openvpn
      SLEEP 1
    fi
  else
    INFO "VPN not up"
    ## Test Internet Connection
    DEBUG "Testing for internet connection"
    if echo -e "GET http://google.com HTTP/1.0\n\n" | nc -w 2 google.com 80 > /dev/null 2>&1 ; then
      DEBUG "Internet is good"
      ## START OPENVPN
      VPNPID=$(pidof openvpn)
      if [ -n "$VPNPID" ]; then
        ERROR "VPN running but no interface yet"
        INFO "Killing OpenVPN process ($VPNPID)"
        kill -9 $VPNPID
      fi
      INFO "Starting VPN"
#     openvpn --config "$VPNCF"
      openvpn --daemon --config "$VPNCF" --writepid "$SELFDIR/openvpn.pid" --auth-user-pass "$VPNPASS" --route-nopull --route-up "$VPNROUTE" --script-security 2
      #WAIT FOR CONNECTION
      SLEEP 15
      if [ "$FWSET" != "1" ] ; then
        ## IPTABLE CONFIG ##
        DEBUG "Enabeling IP Forwardig"
        echo 1 > /proc/sys/net/ipv4/ip_forward
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
        # block everything else incoming on $VPNIF
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
          dhclient $WIFIIF
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
