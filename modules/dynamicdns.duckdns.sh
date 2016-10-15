#!/bin/bash
dynamic_dns_duckdns_reset(){
  DYNDNS=-1
}
dynamic_dns_duckdns(){
  if [ -n $DUCKKEY ] && [ -n $DUCKDOMAIN ] ;then
    if [ "$DYNDNS" != "$(date +%H)" ] ; then
      INFO "Updating Dynamic DNS"
      if su $TORRENTUSER -c "echo -e 'GET http://www.duckdns.org/update?domains=$DUCKDOMAIN&token=$DUCKKEY&ip= HTTP/1.0\n\n' | nc -w 2 www.duckdns.org 80" ; then
        VPNDNS=$DUCKDOMAIN
        DYNDNS=$(date +%H)
      fi
    fi
  else
    ERROR "DUCKDOMAIN, DUCKKEY and/or TORRENTUSER not set"
    check_config "DUCKKEY" "DUCKDNS Key"
    check_config "DUCKDOMAIN" "DUCKDNS Domain (bob.duckdns.org)"
    check_config "TORRENTUSER" "User rTorrent runs as"
  fi
}
