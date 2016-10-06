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
# add MENU SYSTEM
exit 1
