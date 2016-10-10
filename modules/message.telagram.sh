#!/bin/bash
telegram_send(){
  if [ -n "$TELKEY" ] && [ -n "$TELUSERID" ] ; then
    curl -s --max-time 3 -d "chat_id=$TELUSERID&disable_web_page_preview=1&text=$1" "https://api.telegram.org/bot$TELKEY/sendMessage" > /dev/null
  else
    echo "TELUSERID and/or TELKEY not set"
    exit 1
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set TELUSERID= in Config"
  echo "Must set TELKEY= in Config"
fi
