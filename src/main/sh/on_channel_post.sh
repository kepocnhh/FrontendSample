#!/usr/local/bin/bash

SCRIPTS=(
 './src/main/sh/get_file_path.sh'
 './src/main/sh/download_file.sh'
 './src/main/sh/commit_img.sh'
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

if test $# -ne 1; then
 echo 'Wrong arguments!'; exit 1; fi

CHANNEL_POST="$1"

if test -z "${CHANNEL_POST}"; then
 echo 'Channel post is empty!'; exit 1; fi

ACTUAL_CHANNEL_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".chat.id // null")"
if test "${ACTUAL_CHANNEL_ID}" != "${TG_CHANNEL_ID}"; then
 echo 'Ignoring channel'; exit 0; fi
SRC_CHAT_TYPE="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".forward_origin.chat.type // null")"
if test "${SRC_CHAT_TYPE}" != 'channel'; then
 echo 'Not from channel'; exit 0; fi
SRC_CHANNEL_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".forward_origin.chat.id // null")"
if [[ ! "${SRC_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong src channel id!'; exit 1; fi
SRC_MESSAGE_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".forward_origin.message_id // null")"
if [[ ! "${SRC_MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong src message id!'; exit 1; fi
MEDIA_GROUP_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".media_group_id // null")"
if [[ "${MEDIA_GROUP_ID}" != 'null' ]]; then
 echo 'It is the media group'; exit 0; fi
PHOTO_LENGTH="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r "(.photo // []) | length")"
if test "${PHOTO_LENGTH}" == '0'; then
 echo 'No photos'; exit 0; fi
FILE_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -er ".photo[-1].file_id")"
if test $? -ne 0; then
 echo 'Get file id error!'; exit 1
elif test -z "${FILE_ID}"; then
 echo 'File id is empty!'; exit 1
fi
ISSUER='/tmp/file.json'
rm "${ISSUER}"
./src/main/sh/get_file_path.sh "${FILE_ID}" "${ISSUER}" || exit 1
FILE_PATH="$(yq -p=json -er ".result.file_path" "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get file path error!'; exit 1
elif test -z "${FILE_PATH}"; then
 echo 'File path is empty!'; exit 1
fi
ISSUER='/tmp/file.jpg'
rm "${ISSUER}"
./src/main/sh/download_file.sh "${FILE_PATH}" "${ISSUER}" || exit 1
if [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 0; fi

./src/main/sh/commit_img.sh "${ISSUER}" || exit 1
