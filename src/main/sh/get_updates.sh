#!/usr/local/bin/bash

ARGUMENTS=(TG_BOT_ID TG_BOT_TOKEN TG_CHANNEL_ID)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"$ARGUMENT\" is empty!"; exit $((100+INDEX)); fi
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

RESULT_LENGTH="$(yq -er '.result | length' "${ISSUER}")"
if test "${RESULT_LENGTH}" == '0'; then
 echo 'No results'; exit 0
elif [[ ! "${RESULT_LENGTH}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong result length!'; exit 1
fi

for (( INDEX=0; INDEX<RESULT_LENGTH; INDEX++ )); do
 ACTUAL_CHANNEL_ID="$(yq -r ".result[$INDEX].channel_post.chat.id // null" "${ISSUER}")"
 if test "${ACTUAL_CHANNEL_ID}" != "${TG_CHANNEL_ID}"; then
  echo 'Ignoring channel'; continue; fi
 SRC_CHAT_TYPE="$(yq -r ".result[$INDEX].channel_post.forward_origin.chat.type // null" "${ISSUER}")"
 if test "${SRC_CHAT_TYPE}" != 'channel'; then
  echo 'Not from channel'; continue; fi
 SRC_CHANNEL_ID="$(yq -r ".result[$INDEX].channel_post.forward_origin.chat.id // null" "${ISSUER}")"
 if [[ ! "${SRC_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
  echo 'Wrong src channel id!'; continue; fi
 SRC_MESSAGE_ID="$(yq -r ".result[$INDEX].channel_post.forward_origin.message_id // null" "${ISSUER}")"
 if [[ ! "${SRC_MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
  echo 'Wrong src message id!'; continue; fi
 MEDIA_GROUP_ID="$(yq -r ".result[$INDEX].channel_post.media_group_id // null" "${ISSUER}")"
 if [[ "${MEDIA_GROUP_ID}" != 'null' ]]; then
  echo 'It is the media group'; continue; fi
 PHOTO_LENGTH="$(yq -r "(.result[$INDEX].channel_post.photo // []) | length" "${ISSUER}")"
 if test "${PHOTO_LENGTH}" == '0'; then
  echo 'No photos'; continue; fi
 FILE_ID="$(yq -er ".result[$INDEX].channel_post.photo[-1].file_id" "${ISSUER}")"
 if test $? -ne 0; then
  echo 'Get file id error!'; continue; fi
 # todo
done

# todo

echo 'Not implemented!'; exit 1 # todo
