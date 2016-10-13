#!/bin/bash
MONITOR[vpn]=0
monitor_vpn_firewall(){
  if [ "$FWSET" != "1" ] ; then
    DEBUG "Enabeling IP Forwardig"
    echo 1 > /proc/sys/net/ipv4/ip_forward
    #ASYNC Routing enable
    if [ -z $ASYNC ] ; then
      ASYNC=1
      INFO "Keeping inbound traffic on interface"
      ip rule add from $VPNIP/32 table ubuntu priority 100
    fi
    INFO "Adding IPTABLE RULES"
    iptables -F -t nat
    iptables -F -t mangle
    iptables -F -t filter
    ## User packets marked for VPN
    INFO "Marking packets from $TORRENTUSER"
    iptables -t mangle -A OUTPUT -m owner --gid-owner $TORRENTUSER -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -m owner --gid-owner $TORRENTUSER -j CONNMARK --save-mark
    ## ADD ROUTER STUFF
    if [ $APTOVPN -eq 1 ] ; then
      INFO "Sendind $APIF traffic over VPN"
      iptables -t mangle -A PREROUTING -i $APIF -j MARK --set-mark 1
      iptables -t mangle -A PREROUTING -i $APIF -j CONNMARK --save-mark
      iptables -A INPUT -i $APIF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -t nat -A POSTROUTING -o $VPNIF -j MASQUERADE
      iptables -A FORWARD -i $APIF -o $VPNIF -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A FORWARD -i $VPNIF -o $APIF -j ACCEPT
    else
      INFO "Sendind $APIF traffic over LAN"
      iptables -t nat -A POSTROUTING -o $LANIF -j MASQUERADE
      iptables -A FORWARD -i $APIF -o $LANIF -m state --state RELATED,ESTABLISHED -j ACCEPT
      iptables -A FORWARD -i $LANIF -o $APIF -j ACCEPT
    fi
    # allow responses
    iptables -A INPUT -i $VPNIF -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # allow incoming $TORRENTPORT
    iptables -A INPUT -i $VPNIF -p tcp --dport $TORRENTPORT -j ACCEPT
    iptables -A INPUT -i $VPNIF -p udp --dport $TORRENTPORT -j ACCEPT
    # allow incoming DHT
    if [[ "$ENABLEDHT" = "1" ]]; then
      INFO "Enabling DHT firewall rule"
      iptables -A INPUT -i $VPNIF -p udp --dport 6881 -j ACCEPT
      iptables -t raw -I PREROUTING -i $VPNIF -p udp --dport 6881 -j NOTRACK
      iptables -t raw -I OUTPUT -o $VPNIF -p udp --sport 6881 -j NOTRACK
    fi
    ## block everything else incoming on $VPNIF
    iptables -A INPUT -i $VPNIF -j DROP
    ## ALLOW ALL $LANIF
    iptables -A INPUT -i $LANIF -j ACCEPT
    iptables -A OUTPUT -o $LANIF -j ACCEPT
    ## ALLOW ALL $APIF
    iptables -A INPUT -i $APIF -j ACCEPT
    iptables -A OUTPUT -o $APIF -j ACCEPT
    # Allow $LANIF Internal DNS
    iptables -t nat -A PREROUTING -p udp --dport 53 -i $LANIF -j DNAT --to 172.24.1.1:53
    FWSET=1
  fi
}
monitor_vpn_hostname(){
  # update current VPN IP
  DEBUG "Checking $HOSTFILE for $HOST $VPINIP"
  FINDLINE=$(cat $HOSTFILE | egrep -n "\ $HOST$" | tail -n 1)
  FINDLINENR=$(echo $FINDLINE | egrep -o "[0-9]+:" | egrep -o "[0-9]+")
  FINDOLDIP=$(echo $FINDLINE | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
  if [[ -z "$FINDLINENR" ]] || [[ -z "$FINDOLDIP" ]]; then
    ERROR "Couldn't find '$HOST' host in $HOSTFILE"
    INFO "Adding $HOST to $HOSTFILE"
    echo "$VPNIP    $HOST" >> $HOSTFILE
  else
    # check if IP has changed
    if [[ "$VPNIP" != "$FINDOLDIP" ]]; then
      INFO "Updating hosts file '$HOST' to $VPNIP (old: $FINDOLDIP)"
      sed -i.bak -e "$FINDLINENR s/$FINDOLDIP/$VPNIP/" $HOSTFILE
    else
      INFO "$HOSTFILE up to date"
    fi
  fi
}
monitor_vpn(){
  if [  ${MONITOR[Public Internet]} -ge 3  ] ; then
    if [ ${MONITOR[VPN Internet]} -le 2 ] ; then
      local VPNPID=$(cat $SELFDIR/openvpn.pid)
      if [ -n "$VPNPID" ]; then
        INFO "Killing OpenVPN process ($VPNPID)"
        kill -9 $VPNPID
      fi
      INFO "Starting VPN"
      MONITOR[vpn]=2
      openvpn --daemon --config "$VPNCF" --writepid "$SELFDIR/openvpn.pid" --auth-user-pass "$VPNPASS" --route-nopull --route-up "$VPNROUTE" --script-security 2
      #WAIT FOR CONNECTION
      SLEEP 5
      VPNIP=$(ifconfig $VPNIF 2>/dev/null | awk '/inet addr/{print substr($2,6)}')
      if [[ -z "$VPNIP" ]]; then
        MONITOR[vpn]=1
        ERROR "Cannot find IP for $VPNIF."
      else
        MONITOR[vpn]=3
        monitor_vpn_hostname
        monitor_vpn_firewall
        monitor_internet
      fi
    fi
  fi
}
