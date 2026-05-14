#!/usr/local/bin/bash

if test $# -ne 1; then
 echo 'Wrong arguments!'; exit 1; fi

NEW_FILE_INDEX="$1"

if [[ ! "${NEW_FILE_INDEX}" =~ ^(0|[1-9][0-9]*)$ ]]; then
 echo 'Wrong index!'; exit 1; fi

ISSUER="/tmp/file_${NEW_FILE_INDEX}.img"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 1
fi

ISSUER="/tmp/file_${NEW_FILE_INDEX}.json"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

ORIGIN_ID="$(yq -p=json -er '.origin_id' "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get origin id error!'; exit 1; fi
if [[ ! "${ORIGIN_ID}" =~ ^-100[1-9][0-9]*$ ]]; then
 echo 'Wrong origin id!'; exit 1
fi

ORIGIN_MESSAGE_ID="$(yq -p=json -er '.origin_message_id' "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get origin message id error!'; exit 1; fi
if [[ ! "${ORIGIN_MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong origin message id!'; exit 1
fi

ISSUER='src/main/res/ids.bin'
if [[ ! -f "${ISSUER}" || ! -s "${ISSUER}" ]]; then
 printf '%016x%016x' $ORIGIN_ID $ORIGIN_MESSAGE_ID | xxd -p -r > "${ISSUER}"
 if test $? -ne 0; then
  echo "Add ids \"${ISSUER}\" error!"; exit 1; fi
else
 IDS_SIZE="$(wc -c < "${ISSUER}")"
 if [[ "${IDS_SIZE}" -ne 0 && $((IDS_SIZE % 16)) -ne 0 ]]; then
  echo "File \"${ISSUER}\" size is not multiple of 16 bytes!"; exit 1; fi
 cp "${ISSUER}" '/tmp/ids.bin'
 if test $? -ne 0; then
  echo "Copy \"${ISSUER}\" error!"; exit 1; fi
 printf '%016x%016x' $ORIGIN_ID $ORIGIN_MESSAGE_ID | xxd -p -r >> '/tmp/ids.bin'
 if test $? -ne 0; then
  echo 'Add ids error!'; exit 1; fi
 hexdump -v -e '16/1 "%02x" "\n"' '/tmp/ids.bin' | LC_ALL=C sort | xxd -r -p > "${ISSUER}"
 if test $? -ne 0; then
  echo "Sort \"${ISSUER}\" error!"; exit 1; fi
fi

SAVED_TIME=$(TZ=utc date +%s)
if test $? -ne 0; then
 echo 'Get saved time error!'; exit 1
elif [[ ! "${SAVED_TIME}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong saved time!'; exit 1
elif test $SAVED_TIME -gt 4294967295; then
 echo 'Wrong saved seconds!'; exit 1
fi

ISSUER='src/main/res/counts.bin'

if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(wc -c < "${ISSUER}")" -ne 12 ]]; then
 echo "File \"${ISSUER}\" size is not 12 bytes!"; exit 1
fi

COUNTS="$(xxd -p -c 12 "${ISSUER}")"
PUBLISHED_COUNT=$((16#${COUNTS:0:8}))
AWAITING_COUNT=$((16#${COUNTS:8:8} + 1))
COUNTER=$((16#${COUNTS:16:8} + 1))
POST_ID="$(printf '%08x%08x' $SAVED_TIME $COUNTER)"

ISSUER="src/main/res/${POST_ID}.jpg"
if test -f "${ISSUER}"; then
 echo "File \"${ISSUER}\" exists!"; exit 1; fi

cp "/tmp/file_${NEW_FILE_INDEX}.img" "${ISSUER}"
if test $? -ne 0; then
 echo "Copy \"${ISSUER}\" error!"; exit 1
elif [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 1
fi

ISSUER='src/main/res/counts.bin'
printf '%08x%08x%08x' $PUBLISHED_COUNT $AWAITING_COUNT $COUNTER | xxd -p -r > "${ISSUER}"

if test $? -ne 0; then
 echo 'Counts error!'; exit 1; fi

ISSUER='src/main/res/awaiting.bin'
printf '%08x%08x' $SAVED_TIME $COUNTER | xxd -p -r >> "${ISSUER}"

if test $? -ne 0; then
 echo 'Database error!'; exit 1; fi

ISSUER="/tmp/file_${NEW_FILE_INDEX}.json"
JSON_BODY="$(cat "${ISSUER}")"
if test $? -ne 0; then
 echo "Read \"${ISSUER}\" error!"; exit 1; fi

STR_VALUE="${POST_ID}"
JSON_BODY="$(printf '%s' "${JSON_BODY}" | STR_VALUE="${STR_VALUE}" yq -M -p=json -o=json '.post_id=strenv(STR_VALUE)')"
JSON_BODY="$(printf '%s' "${JSON_BODY}" | yq -M -p=json -o=json ".saved_time=${SAVED_TIME}")"

ISSUER="src/main/res/${POST_ID}.json"
printf '%s' "${JSON_BODY}" > "${ISSUER}"
if test $? -ne 0; then
 echo "Write \"${ISSUER}\" error!"; exit 1; fi

git add . && git commit -m "new post ${POST_ID}"

if test $? -ne 0; then
 echo 'Commit error!'; exit 1; fi
