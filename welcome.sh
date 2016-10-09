#!/bin/bash
# Purpose: Display various options to operator using menus
# Author: Vivek Gite < vivek @ nixcraft . com > under GPL v2.0+
# ---------------------------------------------------------------------------
# capture CTRL+C, CTRL+Z and quit singles using the trap
#trap '' SIGINT
#trap ''  SIGQUIT
#trap '' SIGTSTP
# display message and pause 

EXTIPHOST=""
EXTIPFILE=""

if [[ -r extra.sh ]] ; then
  source extra.sh
fi

pause(){
	local m="$@"
	echo "$m"
	read -p "Press [Enter] key to continue..." key
}

# set an 
while :
do
        echo "Gathering info"
        DOWN=$(xmlrpc http://127.0.0.1:80/RPC2/ throttle.global_down.rate | grep integer | cut -d ":" -f 2 | sed -e 's/^[[:space:]]*//')
        DOWN=$(numfmt --to=iec-i --suffix=b $DOWN)
        UP=$(xmlrpc http://127.0.0.1:80/RPC2/ throttle.global_up.rate | grep integer | cut -d ":" -f 2 | sed -e 's/^[[:space:]]*//')
        UP=$(numfmt --to=iec-i --suffix=b $UP)
        PUBIP=$(sudo echo -e "GET http://$EXTIPHOST/$EXTIPFILE HTTP/1.0\n\n" | nc -w 2 $EXTIPHOST 80 | tail -n 1)
        VPNIP=$(su ubuntu -c "echo -e 'GET http://$EXTIPHOST/$EXTIPFILE HTTP/1.0\n\n' | nc -w 2 $EXTIPHOST 80 | tail -n 1")
        # show menu
	clear
        echo "---------------------------------------"
        echo "       rPi rTorrent Auto VPN"
        echo "---------------------------------------"
	echo "---------------------------------------"
	echo "         M A I N - M E N U"
	echo "---------------------------------------"
	echo "1. Restart VPN Script"
	echo "2. Restart OpenVPN"
	echo "3. Restart SSH Tunnel"
	echo "4. Restart rTorrent"
	echo "5. Update Ad Hosts"
	echo "6. Show top memory & cpu eating process"
	echo "7. Show network stats"
	echo "8. Reboot"
	echo "9. Exit"
	echo "---------------------------------------"
        echo "Public IP  $PUBIP"
        echo "OpenVPN IP $VPNIP"
        echo "rTorrent Speed Down: $DOWN  Up: $UP"
        echo "---------------------------------------"
	read -r -p "Enter your choice [1-9] : " c
	# take action
	case $c in
		1) sudo /home/ubuntu/autovpn/vpn.sh -f > /dev/null 2>&1 &;;
		2) sudo killall openvpn;;
		3) sudo killall ssh;;
		4) killall screen;;
		5) sudo /home/ubuntu/autovpn/pihole/gravity.sh;;
		6) clear ; echo '*** Top 10 Memory eating process:'; ps -auxf | sort -nr -k 4 | head -10;
		   echo; pause ; echo '*** Top 10 CPU eating process:';ps -auxf | sort -nr -k 3 | head -10;
		   echo;  pause ; clear;;
		7) netstat -s | less;;
		8) sudo shutdown -r now;;
		9) break;;
		*) Pause "Select between 1 to 9 only"
	esac
done
