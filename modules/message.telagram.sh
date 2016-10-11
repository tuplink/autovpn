#!/bin/bash
telegram_send(){
  if [ -n "$TELKEY" ] && [ -n "$TELUSERID" ] ; then
    local txt=$(printf "$1")
    curl -s --max-time 3 -d "chat_id=$TELUSERID&disable_web_page_preview=1&text=$txt" "https://api.telegram.org/bot$TELKEY/sendMessage" > /dev/null
  else
    ERROR "TELUSERID and/or TELKEY not set"
    exit 1
  fi
}
if [ "$1" == "help" ] ; then
  echo "Must set TELUSERID= in Config"
  echo "Must set TELKEY= in Config"
fi

