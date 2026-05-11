#!/usr/local/bin/bash

SCRIPTS=(
 './src/main/sh/on_channel_post.sh'
)
for (( INDEX=0; INDEX<${#SCRIPTS[@]}; INDEX++ )); do
 ISSUER="${SCRIPTS[INDEX]}"
 if [[ ! -f "${ISSUER}" ]]; then
  echo "No file \"${ISSUER}\"!"; exit 1
 elif [[ ! -s "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is empty!"; exit 1
 elif [[ ! -x "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is not executable!"; exit 1
 fi
done

ARGUMENTS=(TG_BOT_ID TG_BOT_TOKEN TG_CHANNEL_ID)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"${ARGUMENT}\" is empty!"; exit 1; fi
done

if [[ ! "${TG_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong channel id!'; exit 1; fi

ISSUER='/tmp/updates.json'
rm "${ISSUER}"
CODE=$(curl -m 8 -w '%{http_code}' -o "${ISSUER}" \
 "https://api.telegram.org/bot${TG_BOT_ID}:${TG_BOT_TOKEN}/getUpdates" \
 --data-urlencode 'allowed_updates=["channel_post"]')

if test $? -ne 0; then
 echo 'Curl error!'; exit 1
elif [[ "${CODE}" != '200' ]]; then
 echo 'Get updates error!'; exit 1
elif [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

TG_CHECKS="$(yq -er '.ok // false' "${ISSUER}" 2>/dev/null)"

if test $? -ne 0; then
 echo 'Parse error!'; exit 1
elif [[ "${TG_CHECKS}" != 'true' ]]; then
 echo 'Check error!'; exit 1
fi

TG_UPDATES="$(cat "${ISSUER}")"

RESULT_LENGTH="$(echo "${TG_UPDATES}" | yq -er '.result | length')"
if test "${RESULT_LENGTH}" == '0'; then
 echo 'No results'; exit 0
elif [[ ! "${RESULT_LENGTH}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong result length!'; exit 1
fi

for (( INDEX=0; INDEX<RESULT_LENGTH; INDEX++ )); do
 CHANNEL_POST="$(echo "${TG_UPDATES}" | yq ".result[$INDEX].channel_post // null")"
 if test "${CHANNEL_POST}" == 'null'; then
  echo 'No channel post'; continue; fi
 ./src/main/sh/on_channel_post.sh "${CHANNEL_POST}"
done
