#!/bin/bash
MONITOR[ssh]=0
forward_ssh(){
  if [ -n $SSHKEY ] && [ -n $SSHLOCALPORT ] && [ -n $SSHREMOTEPORT ] && [ -n $SSHHOST ] && [ -n $SSHREMOTEUSER ] ; then
    if [  ${MONITOR[Public Internet]} -ge 3  ] ; then 
      DEBUG "Checking status of Reverse Tunnel"
      SSHPID=$(pgrep -f 'ssh -o ConnectTimeout=10')
      if [ -z "$SSHPID" ]; then
        INFO "Starting SSH Tunnel"
        if ssh -o ConnectTimeout=10 -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -fN -i $SSHKEY $SSHREMOTEUSER@$SSHHOST -R $SSHREMOTEPORT:*:$SSHLOCALPORT  > /dev/null 2>&1; then
          MONITOR[ssh]=2
          INFO "SSH tunnel established"
          send_msg "http://$SSHHOST:$SSHREMOTEPORT Forwarded to $SSHLOCALPORT"
        else
          MONITOR[ssh]=1
          ERROR "SSH tunnel failed"
        fi
      else
        MONITOR[ssh]=3
        DEBUG "Reverse tunnel is up"
      fi
    fi
  else
    INFO "SSHKEY, SSHLOCALPORT, SSHREMOTEPORT, SSHHOST and/or SSHREMOTEUSER not set"
    check_config "SSHKEY" "SSH tunnel key"
    check_config "SSHLOCALPORT" "Local port number for reverse tunnel"
    check_config "SSHREMOTEPORT" "Port number on remote host to connect to"
    check_config "SSHHOST" "SSH tunnel host"
    check_config "SSHREMOTEUSER" "SSH Remote username"
  fi
    status
}

