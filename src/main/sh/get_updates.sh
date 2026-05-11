#!/usr/local/bin/bash

SCRIPTS=(
 './src/main/sh/get_file_path.sh'
 './src/main/sh/download_file.sh'
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
 ACTUAL_CHANNEL_ID="$(echo "${CHANNEL_POST}" | yq -r ".chat.id // null")"
 if test "${ACTUAL_CHANNEL_ID}" != "${TG_CHANNEL_ID}"; then
  echo 'Ignoring channel'; continue; fi
 SRC_CHAT_TYPE="$(echo "${CHANNEL_POST}" | yq -r ".forward_origin.chat.type // null")"
 if test "${SRC_CHAT_TYPE}" != 'channel'; then
  echo 'Not from channel'; continue; fi
 SRC_CHANNEL_ID="$(echo "${CHANNEL_POST}" | yq -r ".forward_origin.chat.id // null")"
 if [[ ! "${SRC_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
  echo 'Wrong src channel id!'; continue; fi
 SRC_MESSAGE_ID="$(echo "${CHANNEL_POST}" | yq -r ".forward_origin.message_id // null")"
 if [[ ! "${SRC_MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
  echo 'Wrong src message id!'; continue; fi
 MEDIA_GROUP_ID="$(echo "${CHANNEL_POST}" | yq -r ".media_group_id // null")"
 if [[ "${MEDIA_GROUP_ID}" != 'null' ]]; then
  echo 'It is the media group'; continue; fi
 PHOTO_LENGTH="$(echo "${CHANNEL_POST}" | yq -r "(.photo // []) | length")"
 if test "${PHOTO_LENGTH}" == '0'; then
  echo 'No photos'; continue; fi
 FILE_ID="$(echo "${CHANNEL_POST}" | yq -er ".photo[-1].file_id")"
 if test $? -ne 0; then
  echo 'Get file id error!'; continue
 elif test -z "${FILE_ID}"; then
  echo "File id is empty!"; continue
 fi
 ISSUER='/tmp/file.json'
 rm "${ISSUER}"
 ./src/main/sh/get_file_path.sh "${FILE_ID}" "${ISSUER}" || continue
 FILE_PATH="$(yq -er ".result.file_path" "${ISSUER}")"
 if test $? -ne 0; then
  echo 'Get file path error!'; continue
 elif test -z "${FILE_PATH}"; then
  echo "File path is empty!"; continue
 fi
 ISSUER='/tmp/file.jpg'
 ./src/main/sh/download_file.sh "${FILE_PATH}" "${ISSUER}" || continue
 if [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
  echo "File \"${ISSUER}\" is not jpg!"; continue; fi
 # todo
done

# todo

echo 'Not implemented!'; exit 1 # todo
