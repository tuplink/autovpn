#!/bin/bash
forward(){
  if [ -n "$(declare -f -F forward_ssh)" ] ; then
    forward_ssh
  fi
  if [ -n "$(declare -f -F forward_pia)" ] ; then
    forward_pia
  fi
}

