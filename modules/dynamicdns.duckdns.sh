dynamic_dns_duckdns(){
  if [ -n $DUCKKEY ] && [ -n $DUCKDOMAIN ] ;then
    if [ "$DYNDNS" != "$(date +%H)" ] ; then
      INFO "Updating Dynamic DNS"
      DYNDNS=$(date +%H)
      DNS=$(su $RTORRENTUSER -c "echo -e 'GET http://www.duckdns.org/update?domains=$DUCKDOMAIN&token=$DUCKKEY&ip= HTTP/1.0\n\n' | nc -w 2 www.duckdns.org 80")
    fi
    if [ -z $PUBLICIP ] ; then
      PUBLICIP=$DUCKDOMAIN
    fi
  else
    ERROR "DUCKDOMAIN and/or DUCKKEY not set"
    exit 1
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set DUCKKEY= in Config"
  echo "Must set DUCKDOMAIN= in Config"
fi
