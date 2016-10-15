#!/bin/bash
MONITOR[mount]=0
monitor_mount(){
  if [[ ! -z "$MOUNTCHECK" ]]; then
    DEBUG "Checking if $MOUNTCHECK is mounted"
    local testmount=$(/bin/mount | grep "on $MOUNTCHECK")
    if [[ -z "$testmount" ]]; then
      INFO "Mounting $MOUNTCHECK"
      MONITOR[mount]=2
      mount $MOUNTCHECK
    else
      DEBUG "$MOUNTCHECK is Mounted"
      MONITOR[mount]=3
    fi
  else
    MONITOR[ad]=1
    check_config "MOUNTCHECK" "Mount point to check on(/media/torrentdata)"
  fi
  status
}

