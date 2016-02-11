#!/bin/bash
if [ ! -d /var/run/cloudflare ]; then
  mkdir /var/run/cloudflare
fi

dynamic_dns_cloudflare_reset(){
  CLOUDFLAREDNS=-1
}
dynamic_dns_cloudflare(){
  if [ -n $CLOUDFLARE_EMAIL ] && [ -n $CLOUDFLARE_KEY ] ;then
    if [ "$DYNDNS" != "$(date +%H)" ] ; then
      local record_name=$1
      local zone_name=$2
      local ip=$3
      if [ "$record_name" != "$zone_name" ] && ! [ -z "${record_name##*$zone_name}" ]; then
        record_name="$record_name.$zone_name"
        DEBUG "Hostname is not a FQDN, assuming $record_name"
      fi
      if [ -f /var/run/cloudflare/$record_name.txt ]; then
        old_ip=$(cat /var/run/cloudflare/$record_name.txt)
        if [ $ip == $old_ip ]; then
          DEBUG "IP has not changed."
       fi
     fi

     if [ -f /var/run/cloudflare/$record_name.id ] && [ $(wc -l /var/run/cloudflare/$record_name.id | cut -d " " -f 1) == 2 ]; then
        zone_identifier=$(head -1 /var/run/cloudflare/$record_name.id)
        record_identifier=$(tail -1 /var/run/cloudflare/$record_name.id)
      else
        zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name" -H "X-Auth-Email: $CLOUDFLARE_EMAIL" -H "X-Auth-Key: $CLOUDFLARE_KEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
        record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $CLOUDFLARE_EMAIL" -H "X-Auth-Key: $CLOUDFLARE_KEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
        if [[ -z "$record_identifier" ]] ; then
          DEBUG "Adding $record_name to CloudFlare"
          add_record=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" -H "X-Auth-Email: $CLOUDFLARE_EMAIL" -H "X-Auth-Key: $CLOUDFLARE_KEY" -H "Content-Type: application/json" --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"0.0.0.0\"}")
          record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_name" -H "X-Auth-Email: $CLOUDFLARE_EMAIL" -H "X-Auth-Key: $CLOUDFLARE_KEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
        fi
        if [[ -z "$zone_identifier" ]] || [[ -z "$record_identifier" ]]; then
          echo "Quiting ZoneID($zone_identifier)RecordID($record_identifier)"
#      exit
        fi
        echo "$zone_identifier" > "/var/run/cloudflare/$record_name.id"
        echo "$record_identifier" >> "/var/run/cloudflare/$record_name.id"
      fi

      update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $CLOUDFLARE_EMAIL" -H "X-Auth-Key: $CLOUDFLARE_KEY" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$ip\"}")

      if [[ $update == *"\"success\":false"* ]]; then
        message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
        DEBUG "$message"
        echo -e "$message"
      else
        echo "$ip" > /var/run/cloudflare/$record_name.txt
        INFO "IP changed to: $ip"
        VPNDNS=$DUCKDOMAIN
        CLOUDFLAREDNS=$(date +%H)
      fi
    fi
  else
    ERROR "CLOUDFLARE_EMAIL, CLOUDFLARE_KEY"
    check_config "CLOUDFLARE_KEY" "Cloudflare API Key"
    check_config "CLOUDFLARE_EMAIL" "Cloudflare eMail"
  fi
}

