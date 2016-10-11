monitor_rtorrent(){
  if [ -n $TORRENTUSER ] && [ -n $SCREENNAME ] ; then
    ##  RTORRENT CHECK ##
    DEBUG "Check if rtrrent is up"
    TESTSCREEN=$(su $TORRENTUSER -c 'screen -ls | egrep "[0-9]+.$SCREENNAME"')
    if [[ -n "$TESTSCREEN" ]]; then
      INFO "rTorrent is running."
    else
      INFO "Starting rTorrent"
      stty stop undef 2>/dev/null
      stty start undef 2>/dev/null
      su $TORRENTUSER -c "screen -A -dmS $SCREENNAME /usr/local/bin/rtorrent"
    fi
  else
    INFO "TORRENTUSER and/or SCREENNAME not set"
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set TORRENTUSER= in Config"
  echo "Must set SCREENNAME= in Config"
fi

