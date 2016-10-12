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
    exit 1
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set DUCKKEY= in Config"
  echo "Must set DUCKDOMAIN= in Config"
  echo "Must set TORRENTUSER= in config"
fi
