#!/bin/bash
MONITOR[ssh]=0
forward_ssh(){
  if [ -n $SSHKEY ] && [ -n $SSHLOCALPORT ] && [ -n $SSHREMOTEPORT ] && [ -n $SSHHOST ] && [ -n $SSHREMOTEUSER ]; then
    DEBUG "Checking status of Reverse Tunnel"
    SSHPID=$(pgrep -f 'ssh -o ConnectTimeout=10')
    if [ -z "$SSHPID" ]; then
      INFO "Starting SSH Tunnel"
      if ssh -o ConnectTimeout=10 -o ExitOnForwardFailure=yes -fN -i $SSHKEY $SSHREMOTEUSER@$SSHHOST -R $SSHREMOTEPORT:*:$SSHLOCALPORT  > /dev/null 2>&1; then
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
  else
    INFO "SSHKEY, SSHLOCALPORT, SSHREMOTEPORT, SSHHOST and/or SSHREMOTEUSER not set"
  fi
  status
}
if [ "$1" == "help" ] ; then
  echo "Must set SSHKEY= in Config"
  echo "Must set SSHLOCALPORT= in Config"
  echo "Must set SSHREMOTEPORT= in Config"
  echo "Must set SSHHOST= in Config"
  echo "Must set SSHREMOTEUSER= in Config"
fi

