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
      status_msg
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
    elif [[ "$REPLY" == *"setvar"* ]] ; then
      local txt=${REPLY#* }
      local val=${txt#*=}
      local var=${txt%=*}
      local var=${var^^}
      export $var=$val
      send_msg "$var set to $BOB"
    elif [ "$REPLY" == "reboot" ] ; then
      send_msg "Rebooting system now"
      reboot
    elif [ "$REPLY" == "help" ] ; then
      send_msg "Known Commands: \n Help \n Status \n Reboot \n Restart OpenVPN \n Restart rTorrent \n Restart SSH \n Restart script \n setvar <name>=<val>"
    else
      send_msg "Unknown command $REPLY. Send HELP for more info"
    fi
  fi
}
