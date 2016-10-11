#!/bin/bash
#ALL FUNCTION SHOULD SET $REPLY
reply_msg(){
  if [ -n "$(declare -f -F telegram_reply)" ] ; then
    telegram_reply
  else
    echo "No way to send message $@"
  fi
  REPLY=${REPLY,,}
  if [ -n "$REPLY" ] ; then
    INFO "Recived message $REPLY"
    if [ "$REPLY" == "status" ] ; then
      send_msg "INSERT STATUS HERE"
    elif [[ "$REPLY" == "restart"* ]] ; then
      if [[ "$REPLY" == *"openvpn" ]] ; then
        send_msg "Restarting OpenVPN"
        killall openvpn
      elif [[ "$REPLY" == *"rtorrent" ]] ; then
        send_msg "Restarting rTorrent"
        killall screen
      elif [[ "$REPLY" == *"ssh" ]] ; then
        send_msg "Restarting SSH Tunnel"
        killall ssh
      elif [[ "$REPLY" == *"script" ]] ; then
        systemctl restart autovpn.service
      else
        send_msg "Unknown Command $REPLY"
      fi
    elif [ "$REPLY" == "reboot" ] ; then
      send_msg "Rebooting system now"
      reboot
    elif [ "$REPLY" == "help" ] ; then
      send_msg "Known Commands: Help, Status, Reboot, Restart OpenVPN, Restart rTorrent, Restart SSH, Restart script"
    else
      send_msg "Unknown command $REPLY. See HELP for more info"
    fi
  fi
}

