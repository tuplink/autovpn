#!/bin/bash
telegram_send(){
  if [ -n "$TELKEY" ] && [ -n "$TELUSERID" ] ; then
    local txt=$(printf "$1")
    curl -s --max-time 3 -d "chat_id=$TELUSERID&disable_web_page_preview=1&text=$txt" "https://api.telegram.org/bot$TELKEY/sendMessage" > /dev/null
  else
    ERROR "TELUSERID and/or TELKEY not set"
    check_config "TELUSERID" "Telagram User id(123453)"
    check_config "TELKEY" "Telagram API Key(ks8234:1234jkluio89ksad8)"
  fi
}

