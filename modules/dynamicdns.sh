#!/bin/bash
dynamic_dns_reset(){
  if [ -n "$(declare -f -F dynamic_dns_duckdns_reset)" ] ; then
    dynamic_dns_cloudflare_reset
  fi
  if [ -n "$(declare -f -F dynamic_dns_duckdns_reset)" ] ; then
    dynamic_dns_cloudflare_reset
  fi
}

dynamic_dns(){
  if [ ${MONITOR[VPN Internet]} -ge 3 ] ; then
    if [ -n "$(declare -f -F dynamic_dns_cloudflare)" ] ; then
      dynamic_dns_cloudflare $CLOUDFLARE_PUB $CLOUDFLARE_DOMAIN
    elif [ -n "$(declare -f -F dynamic_dns_duckdns)" ] ; then
      dynamic_dns_duckdns
    else
      INFO "No dynamic dns Plugin enabled"
    fi
    #Ono of these services should provide us with a VPN DNS
    if [ -z "$VPNDNS" ] ; then
      ERROR "No service to provide public ip"
      VPNDNS="UNKNOWN"
    fi
  else
    INFO "Cant do DYNAMICDNS no VPN Internet"
  fi
}
