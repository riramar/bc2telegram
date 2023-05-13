#!/bin/bash

TELBOTOKEN="123456789:AAA..."
TELCHATID="123456789"
BCPURL="https://polling.burpcollaborator.net/burpresults?biid=abcdef..."
TZDATE="America/Sao_Paulo"
HTTPFILTER="scaninfo@paloaltonetworks.com"
DNSFILTER="example.com"
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
                                if [[ ${SUBDOMAIN,,} =~ ${DNSFILTER} ]]; then
                                        continue
                                else
                                        MSG+="DNS Type: ${DNSTYPE}\n"
                                        MSG+="Subdomain: ${SUBDOMAIN}\n"
                                fi
                                MSG+="DNS Type: ${DNSTYPE}\n"
                                MSG+="Subdomain: ${SUBDOMAIN}\n"
                        elif [ "${PROTOCOL}" == "smtp" ]; then
                                SENDER="$(echo ${LINE} | jq -rM '.data.sender')"
                                RCPTS="$(echo ${LINE} | jq -rM '.data.recipients[]')"
                                SMTPMSG="$(echo ${LINE} | jq -rM '.data.message' | base64 -d)"
                                CONVERSATION="$(echo ${LINE} | jq -rM '.data.conversation' | base64 -d)"
                                MSG+="SMTP Sender: $(echo ${SENDER} | base64 -d)\n"
                                MSG+="SMTP Recipients: $(echo ${RCPTS} | while read RCPT; do echo ${RCPT} | base64 -d; echo "\n"; done)"
                                MSG+="SMTP Message:\n"
                                MSG+="-----------------------------------------------------------------------------\n"
                                MSG+="${SMTPMSG}"
                                MSG+="\n"
                                MSG+="-----------------------------------------------------------------------------\n"
                                MSG+="SMTP Conversation:\n"
                                MSG+="-----------------------------------------------------------------------------\n"
                                MSG+="${CONVERSATION}"
                                MSG+="\n"
                                MSG+="-----------------------------------------------------------------------------\n"
                        else
                                HTTPREQUEST="$(echo ${LINE} | jq -rM '.data.request' | base64 -d)"
                                HTTPRESPONSE="$(echo ${LINE} | jq -rM '.data.response' | base64 -d)"
                                if [[ ${HTTPREQUEST,,} =~ ${HTTPFILTER} ]]; then
                                        continue
                                else
                                        MSG+="HTTP Request:\n"
                                        MSG+="-----------------------------------------------------------------------------\n"
                                        MSG+="${HTTPREQUEST}"
                                        MSG+="\n"
                                        MSG+="-----------------------------------------------------------------------------\n"
                                        MSG+="HTTP Response:\n"
                                        MSG+="-----------------------------------------------------------------------------\n"
                                        MSG+="${HTTPRESPONSE}"
                                        MSG+="\n"
                                        MSG+="-----------------------------------------------------------------------------\n"
                                fi
                        fi
                        MSG+="====================================="
                        echo -e "${MSG}"
                        TOTALSIZE="${#MSG}"
                        OFFSET="0"
                        while [ "${TOTALSIZE}" -gt "0" ]; do
                                CHUNKMSG="${MSG:${OFFSET}:${MSGSIZE}}"
                                CHUNKMSG="${CHUNKMSG//\"/\\\"}"
                                curl -s -o /dev/null -X POST -H 'Content-Type: application/json' -d "{\"chat_id\": \"${TELCHATID}\", \"text\": \"${CHUNKMSG}\"}" "https://api.telegram.org/bot${TELBOTOKEN}/sendMessage"
                                OFFSET="$((${OFFSET}+${MSGSIZE}))"
                                TOTALSIZE="$((${TOTALSIZE}-${MSGSIZE}))"
                        done

                done
        fi
        sleep "${DELAY}"
done
