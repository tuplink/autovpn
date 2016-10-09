#!/bin/bash
#TODO
#add rout table
#add rtorrent stuff
##STATTIC STUFF
SELF=${BASH_SOURCE[0]}
SELFDIR="$( cd "$( dirname "$SELF" )" && pwd )"

#VPNPASSFILE="openvpn/PIA/user.txt"
VPNPASSFILE="vpnpassfile"
#VPN STUFF
setup_vpn(){
  echo "Going to setup VPN"
  apt-get install openvpn
  echo "ENTER VPN Username, followed by [ENTER]:"
  read user
  echo "ENTER VPN Password, followed by [ENTER]:"
  read pass
  echo "MAKING Password file"
  echo "$user" > newfile
  echo "$pass" >> newfile
  echo "Creating custom route table"
  echo "200	ubuntu" >> /etc/iproute2/rt_tables
  echo "a reboot will be required"
  echo ":::VPN SETUP FINISHED::::"
}

setup_sndmasq(){
  apt-get install dnsmasq
  echo "addn-hosts=$SELFDIR/pihole/gravity.list" >> /etc/dnsmasq.conf
}
setup_initd(){
  cp autovpn_rc /etc/init.d/autovpn
  chmod 755 /etc/init.d/autovpn
  update-rc.d autovpn defaults
}
setup_systemd(){
  echo "[Unit]
    Description=AutoVPN daemon
    After=network.target

    [Service]
    Type=simple
    KillMode=none
    WorkingDirectory=$SELFDIR/
    ExecStart=$SELFDIR/vpn.sh -q -f
    ExecReload=$SELFDIR/vpn.sh -q -f
    KillMode=process
    Restart=on-failure

    [Install]
    WantedBy=default.target" > /etc/systemd/system/autovpn.service
    chmod 664 /etc/systemd/system/autovpn.service
    systemctl daemon-reload
    systemctl start autovpn.service
}
setup_all(){
  setup_vpn
  setup_dnsmasq
  setup_systemd
}

# add MENU SYSTEM


exit 1
