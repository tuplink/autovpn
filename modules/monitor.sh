#!/bin/bash
declare -A MONITOR
monitor(){
  if [ -n "$(declare -f -F monitor_mount)" ] ; then
    monitor_mount
  fi
  if [ -n "$(declare -f -F monitor_rtorrent)" ] ; then
    monitor_rtorrent
  fi
  if [ -n "$(declare -f -F monitor_ads)" ] ; then
    monitor_ads
  fi
}

