#!/bin/bash
dynamic_dns(){
  if [ -n "$(declare -f -F dynamic_dns_duckdns)" ] ; then
    dynamic_dns_duckdns
  else
    INFO "No dynamic dns Plugin enabled"
  fi
}

