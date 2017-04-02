#!/bin/bash
forward_pia(){
  DEBUG "Checking if we need to run port forward script"
  if [ -n $VPNIF ] && [ -n $VPNPASS ] ; then
    if [ ${MONITOR[VPN Internet]} -ge 3 ] ; then
      if [ "$PORTFOR" != $(date +%H) ] ; then
        PORT=$($SELFDIR/portforward/port_forward.sh -f $VPNPASS -i $VPNIF -s)
        if [[ $PORT =~ ^-?[0-9]+$ ]] ; then
          PORTFOR=$(date +%H)
          DEBUG "Inbound port is $PORT"
          if [ "$PORT" != "$OLDPORT" ] || [ -z $OLDPORT ] ; then
            INFO "Port Number changed"
            DEBUG "Adding new rule for inbound port"
            iptables -D INPUT -i $VPNIF -j DROP
            if [ -n "$OLDPORT" ] ; then
              iptables -t nat -D PREROUTING -i $VPNIF -p tcp --dport $OLDPORT -j REDIRECT --to-port 80
            fi
            iptables -t nat -A PREROUTING -i $VPNIF -p tcp --dport $PORT -j REDIRECT --to-port 80
            iptables -A INPUT -i $VPNIF -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
            iptables -A INPUT -i $VPNIF -j DROP
            OLDPORT=$PORT
            send_msg "http://$VPNDNS:$PORT Forwarded to 80"
          else
            INFO "Port is same as old"
          fi
        else
          INFO "Port forward enable failed"
        fi
      fi
    fi
  else
    INFO "VPNIF and/or VPNPASS not set"
    check_config "VPNIF" "VPN Interface name (tun0)"
    check_config "VPNPASS" "VPN login file (/home/ubuntu/vpn.txt). line 1Username Line2 Password"
  fi
  status
}
