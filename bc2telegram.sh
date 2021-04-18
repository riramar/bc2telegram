#!/bin/bash

TELBOTOKEN="123456789:AAA..."
TELCHATID="123456789"
BCPURL="https://polling.burpcollaborator.net/burpresults?biid=abcdef..."
TZDATE="America/Sao_Paulo"
MSGSIZE="4096"
DELAY="2"

while true; do
	RESULTS=$(curl -sk "${BCPURL}")
	if [ "${RESULTS}" != "{}" ]; then
		echo "${RESULTS}" | jq -cM '.responses[]' | \
		while read LINE; do
			DATETIME="$(echo ${LINE} | jq -rM '.time' | TZ="${TZDATE}" date)"
			PROTOCOL="$(echo ${LINE} | jq -rM '.protocol')"
			SOURCEIP="$(echo ${LINE} | jq -rM '.client')"
			BURPSTRING="$(echo ${LINE} | jq -rM '.interactionString')"
			MSG="=====================================\n"
			MSG+="Time: ${DATETIME}\n"
			MSG+="Protocol: ${PROTOCOL}\n"
			MSG+="Source IP: ${SOURCEIP}\n"
			MSG+="Burp String: ${BURPSTRING}\n"
			if [ "${PROTOCOL}" == "dns" ]; then
				DNSTYPE="$(echo ${LINE} | jq -rM '.data.type')"
				SUBDOMAIN="$(echo ${LINE} | jq -rM '.data.subDomain')"
				MSG+="DNS Type: ${DNSTYPE}\n"
				MSG+="Subdomain: ${SUBDOMAIN}\n"
			elif [ "${PROTOCOL}" == "smtp" ]; then
				SENDER="$(echo ${LINE} | jq -rM '.data.sender')"
				RCPTS="$(echo ${LINE} | jq -rM '.data.recipients[]')"
				SMTPMSG="$(echo ${LINE} | jq -rM '.data.message')"
				CONVERSATION="$(echo ${LINE} | jq -rM '.data.conversation')"
				MSG+="SMTP Sender: $(echo ${SENDER} | base64 -d)\n"
				MSG+="SMTP Recipients: $(echo ${RCPTS} | while read RCPT; do echo ${RCPT} | base64 -d; echo "\n"; done)"
				MSG+="SMTP Message:\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="$(echo ${SMTPMSG} | base64 -d)"
				MSG+="\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="SMTP Conversation:\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="$(echo ${CONVERSATION} | base64 -d)"
				MSG+="\n"
				MSG+="-----------------------------------------------------------------------------\n"
			else
				HTTPREQUEST="$(echo ${LINE} | jq -rM '.data.request')"
				HTTPRESPONSE="$(echo ${LINE} | jq -rM '.data.response')"
				MSG+="HTTP Request:\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="$(echo ${HTTPREQUEST} | base64 -d)"
				MSG+="\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="HTTP Response:\n"
				MSG+="-----------------------------------------------------------------------------\n"
				MSG+="$(echo ${HTTPRESPONSE} | base64 -d)"
				MSG+="\n"
				MSG+="-----------------------------------------------------------------------------\n"
			fi
			MSG+="====================================="
			echo -e "${MSG}"
			MSG="${MSG//\"/\\\"}"
			TOTALSIZE="${#MSG}"
			OFFSET="0"
			while [ "${TOTALSIZE}" -gt "0" ]; do
				curl -s -o /dev/null -X POST -H 'Content-Type: application/json' -d "{\"chat_id\": \"${TELCHATID}\", \"text\": \"${MSG:${OFFSET}:${MSGSIZE}}\"}" "https://api.telegram.org/bot${TELBOTOKEN}/sendMessage"
				OFFSET="$((${OFFSET}+${MSGSIZE}))"
				TOTALSIZE="$((${TOTALSIZE}-${MSGSIZE}))"
			done
			
		done
	fi
	sleep "${DELAY}"
done