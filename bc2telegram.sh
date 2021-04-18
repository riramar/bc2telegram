#!/bin/bash

TELBOTOKEN="123456789:jbd78sadvbdy63d37gda37bd8"
TELCHATID="123456789"
BCPURL="https://polling.burpcollaborator.net/burpresults?biid=abcdef..."
TZDATE="America/Sao_Paulo"
DELAY=2

while true; do
  RESULTS=$(curl -sk "${BCPURL}")
  if [ "${RESULTS}" != "{}" ]; then
    echo "${RESULTS}" | jq -cM '.responses[]' | \
    while read LINE; do
      DATETIME=$(echo ${LINE} | jq -rM '.time' | TZ="${TZDATE}" date)
      PROTOCOL=$(echo ${LINE} | jq -rM '.protocol')
      SOURCEIP=$(echo ${LINE} | jq -rM '.client')
      BURPSTRING=$(echo ${LINE} | jq -rM '.interactionString')
      MSG="=====================================\n"
      MSG+="Time: ${DATETIME}\n"
      MSG+="Protocol: ${PROTOCOL}\n"
      MSG+="Source IP: ${SOURCEIP}\n"
      MSG+="Burp String: ${BURPSTRING}\n"
      if [ "${PROTOCOL}" == "dns" ]; then
        DNSTYPE=$(echo ${LINE} | jq -rM '.data.type')
        SUBDOMAIN=$(echo ${LINE} | jq -rM '.data.subDomain')
        MSG+="DNS Type: ${DNSTYPE}\n"
        MSG+="Subdomain: ${SUBDOMAIN}\n"
      else
        HTTPREQUEST=$(echo ${LINE} | jq -rM '.data.request')
        HTTPRESPONSE=$(echo ${LINE} | jq -rM '.data.response')
        MSG+="HTTP Request:\n"
        MSG+="-----------------------------------------------------------------------------\n"
        MSG+=$(echo "${HTTPREQUEST}" | base64 -d)
        MSG+="\n"
        MSG+="-----------------------------------------------------------------------------\n"
        MSG+="HTTP Response:\n"
        MSG+="-----------------------------------------------------------------------------\n"
        MSG+=$(echo "${HTTPRESPONSE}" | base64 -d)
        MSG+="\n"
        MSG+="-----------------------------------------------------------------------------\n"
      fi
      MSG+="====================================="
      echo -e "${MSG}"
      curl -s -o /dev/null -X POST -H 'Content-Type: application/json' -d "{\"chat_id\": \"${TELCHATID}\", \"text\": \"${MSG}\"}" "https://api.telegram.org/bot${TELBOTOKEN}/sendMessage"
    done
  fi
  sleep "${DELAY}"
done