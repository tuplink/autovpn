#!/bin/bash
MONITOR[rtorrent]=0
monitor_rtorrent_speed(){
  #SLOW=1
  if [ -n $GPIOPINBANDWITH ] ; then
    if [ ! -f /sys/class/gpio/gpio$GPIOPINBANDWITH/value ] ; then
      echo 0 > /sys/class/gpio/export
    fi
    torrentslow=$(cat /sys/class/gpio/gpio$GPIOPINBANDWITH/value)
    if [[ $torrentslow -ne 1 ]] && [[ $slow -ne 1 ]] ; then
      xmlrpc localhost throttle.global_down.max_rate.set_kb "" 1
      INFO "rTorrent Slowed Down"
      slow=1
      fast=0
    elif [[ $torrentslow -eq 1 ]] && [[ $fast -ne 1 ]] ; then
      xmlrpc localhost throttle.global_down.max_rate.set_kb "" 1024
      INFO "rTorrent Speed Up"
      slow=0
      fast=1
    fi
  else
    DEBUG "rTorrent Throtle Switch net set \"GPIOPINBANDWITH\""
  fi
}
if [ -n "$(declare -f -F monitor_rtorrent_speed)" ] ; then
  echo "$GPIOPINBANDWITH" > /sys/class/gpio/export
  echo "in" > /sys/class/gpio/gpio$GPIOPINBANDWITH/direction
fi
monitor_rtorrent(){
  if [ -n $TORRENTUSER ] && [ -n $SCREENNAME ] ; then
    if [ ${MONITOR[VPN Internet]} -ge 3 ] && [ ${MONITOR[mount]} -ge 3 ]; then
      ##  RTORRENT CHECK ##
      DEBUG "Check if rtrrent is up"
      TESTSCREEN=$(su $TORRENTUSER -c 'screen -ls | egrep "[0-9]+.$SCREENNAME"')
      if [[ -n "$TESTSCREEN" ]]; then
        INFO "rTorrent is running."
        MONITOR[rtorrent]=3
        monitor_rtorrent_speed
      else
        INFO "Starting rTorrent"
        stty stop undef 2>/dev/null
        stty start undef 2>/dev/null
        su $TORRENTUSER -c "screen -A -dmS $SCREENNAME /usr/local/bin/rtorrent"
        MONITOR[rtorrent]=2
        slow=0
        fast=0
      fi
    fi
  else
    INFO "TORRENTUSER and/or SCREENNAME not set"
    MONITOR[rtorrent]=1
    check_config "TORRRENTUSER" "User rTorrent runs as"
    check_config "SCREENNAME" "Name for a SCREEN session for rtorrent"
  fi
  status
}


