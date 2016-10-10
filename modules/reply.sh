#!/bin/bash
#ALL FUNCTION SHOULD SET $REPLY
reply_msg(){
  if [ -n "$(declare -f -F telegram_reply)" ] ; then
    telegram_reply
  else
    echo "No way to send message $@"
  fi
  shopt -s nocasematch
  if [ -n "$REPLY" ] ; then
    INFO "Recived message $REPLY"
    if [ "$REPLY" == "Status" ] ; then
      send_msg "INSERT STATUS HERE"
    elif [[ "$REPLY" == "Restart"* ]] ; then
      if [[ "$REPLY" == *"openvpn" ]] ; then
        send_msg "Restarting OpenVPN"
        killall openvpn
      elif [[ "$REPLY" == *"rtorrent" ]] ; then
        send_msg "Restarting rTorrent"
        killall screen
      elif [[ "$REPLY" == *"ssh" ]] ; then
        send_msg "Restarting SSH Tunnel"
        killall ssh
      elif [["$REPLY" == *"script"]] ; then
        killall vpn.sh
      fi
    elif [ "$REPLY" == "Help" ] ; then
      send_msg "Known Commands: Help, Status, Restart, Restart openvpn, Restart rtorrent, Restart ssh, Restart script"
    else
      send_msg "Unknown Command $REPLY"
    fi
    shopt -u nocasematch
  fi
}

