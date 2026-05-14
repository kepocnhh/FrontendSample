#!/usr/local/bin/bash

scripts='./src/main/sh'
NAMES=(
 'binary_search.sh'
 'tg_get_file.sh'
 'tg_download_file.sh'
)
for (( INDEX=0; INDEX<${#NAMES[@]}; INDEX++ )); do
 ISSUER="$scripts/${NAMES[INDEX]}"
 if [[ ! -f "${ISSUER}" ]]; then
  echo "No file \"${ISSUER}\"!"; exit 1
 elif [[ ! -s "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is empty!"; exit 1
 elif [[ ! -x "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is not executable!"; exit 1
 fi
done

if test $# -ne 2; then
 echo 'Wrong arguments!'; exit 1; fi

CHANNEL_POST="$1"
NEW_FILE_ID="$2"

ARGUMENTS=(CHANNEL_POST NEW_FILE_ID TG_CHANNEL_ID)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"${ARGUMENT}\" is empty!"; exit 1; fi
done

SRC_CHAT_TYPE="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r '.forward_origin.chat.type // null')"
if test "${SRC_CHAT_TYPE}" != 'channel'; then
 echo 'Not from channel'; exit 204; fi

#

SRC_CHANNEL_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r '.forward_origin.chat.id // null')"
if [[ ! "${SRC_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong src channel id!'; exit 1
elif test "${SRC_CHANNEL_ID}" == "${TG_CHANNEL_ID}"; then
 echo 'Self posted!'; exit 204; fi
SRC_MESSAGE_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r '.forward_origin.message_id // null')"
if [[ ! "${SRC_MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong src message id!'; exit 1; fi

ISSUER='src/main/res/ids.bin'
TARGET_HEX="$(printf '%016x%016x' $SRC_CHANNEL_ID $SRC_MESSAGE_ID)"
FOUND_INDEX="$($scripts/binary_search.sh "${ISSUER}" 16 "${TARGET_HEX}" 'C')"
if test $? -ne 0; then
 echo 'Search id error!'; exit 1
elif [[ ! "${FOUND_INDEX}" =~ ^(-1|0|[1-9][0-9]*)$ ]]; then
 echo 'Wrong index!' >&2; exit 1
elif test $FOUND_INDEX -ge 0; then
 echo "Ids ${SRC_CHANNEL_ID}/${SRC_MESSAGE_ID} found"; exit 204; fi

#

MEDIA_GROUP_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r '.media_group_id // null')"
if [[ "${MEDIA_GROUP_ID}" != 'null' ]]; then
 echo 'It is the media group'; exit 204; fi
PHOTO_LENGTH="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r '(.photo // []) | length')"
if test "${PHOTO_LENGTH}" == '0'; then
 echo 'No photos'; exit 204; fi
FILE_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -er '.photo[-1].file_id')"
if test $? -ne 0; then
 echo 'Get file id error!'; exit 1
elif test -z "${FILE_ID}"; then
 echo 'File id is empty!'; exit 1
fi

ISSUER='/tmp/file.json'
rm "${ISSUER}"
$scripts/tg_get_file.sh "${FILE_ID}" "${ISSUER}" || exit 1
FILE_PATH="$(yq -p=json -er ".result.file_path" "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get file path error!'; exit 1
elif test -z "${FILE_PATH}"; then
 echo 'File path is empty!'; exit 1
fi

ISSUER="/tmp/file_${NEW_FILE_ID}.img"
rm "${ISSUER}"
$scripts/tg_download_file.sh "${FILE_PATH}" "${ISSUER}" || exit 1
if [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 204; fi

ISSUER="/tmp/file_${NEW_FILE_ID}.yml"
echo "
origin_id: ${SRC_CHANNEL_ID}
message_id: ${SRC_MESSAGE_ID}
" > "${ISSUER}"
