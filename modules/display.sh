#!/bin/bash
function DISPLAY(){
  if [ "$QUIET" != "1" ] ;then
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
    HALFCOLS=$(expr $COLS/2)
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
  fi
}

SYSTEM(){
  local function_name="${FUNCNAME[1]}"
  local msg="$1"
  timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
  DISPLAY "[$timeAndDate] [SYSTEM] $msg$"
  echo "[$timeAndDate] [SYSTEM] $msg" >> $SCRIPT_LOG
  logger "[$timeAndDate] [VPN.sh] $msg"
}

ERROR(){
 if [ "$ERRORLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "[$timeAndDate] [ERROR]  $msg"
    echo "[$timeAndDate] [ERROR]  $msg" >> $SCRIPT_LOG
  fi
}
INFO(){
  if [ "$INFOLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "[$timeAndDate] [INFO]   $msg"
    echo "[$timeAndDate] [INFO]   $msg" >> $SCRIPT_LOG
  fi
}
DEBUG(){
  if [ "$DEBUGLOG" == "1" ] ; then
    local function_name="${FUNCNAME[1]}"
    local msg="$1"
    timeAndDate=`date "+%m/%d/%y %H:%M:%S"`
    DISPLAY "[$timeAndDate] [DEBUG]  $msg"
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
SLEEP(){
  local sleep=0
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
