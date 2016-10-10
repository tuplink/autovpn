#!/bin/bash
telegram_reply(){
  if [ -n "$TELKEY" ] && [ -n "$TELUSERID" ] ; then
    local LASTUPDATEID=$(cat LASTUPDATEID.telagraph)
    local UPDATES=$(curl -s --max-time 3 -d "limit=5&offset=$LASTUPDATEID" "https://api.telegram.org/bot$TELKEY/getUpdates")
    UPDATES=$(echo $UPDATES | tr ',' '\n' | tr '[' '{' | tr '{' '\n' | tr '}' '\n' | tr ']' '\n' | tr -d '"' | grep 'update_id\|id\|text\|ok')
    oIFS="$IFS"
    IFS=$'\n'
    local i
    for i in $UPDATES ; do
      if [ "${i%:*}" == "ok" ] ; then
        local VALID=${i##*:}
      elif [ "${i%:*}" == "update_id" ] ; then
        local UPDATEID=${i##*:}
      elif [ "${i%:*}" == "id" ] ; then
        local ID=${i##*:}
      elif [ "${i%:*}" == "text" ] ; then
        local TEXT=${i##*:}
      fi
    done
    IFS="$oIFS"
    if [ "$VALID" == "true" ] && [ "$ID" == "$TELUSERID" ] ; then
      if [ "$LASTUPDATEID" != "$UPDATEID" ] ; then
        echo $UPDATEID > LASTUPDATEID.telagraph
        REPLY=$TEXT
      else
        REPLY=""
      fi
    fi
  else
    ERROR "TELUSERID and/or TELKEY not set"
    exit 1
  fi
}
