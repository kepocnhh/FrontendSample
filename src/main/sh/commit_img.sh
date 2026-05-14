#!/usr/local/bin/bash

if test $# -ne 1; then
 echo 'Wrong arguments!'; exit 1; fi

NEW_FILE_ID="$1"

ISSUER="/tmp/file_${NEW_FILE_ID}.img"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 1
fi

ISSUER="/tmp/file_${NEW_FILE_ID}.yml"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

ORIGIN_ID="$(yq -p=yml -er '.origin_id' "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get origin id error!'; exit 1; fi
if [[ ! "${ORIGIN_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong origin id!'; exit 1
fi

MESSAGE_ID="$(yq -p=yml -er '.message_id' "${ISSUER}")"
if test $? -ne 0; then
 echo 'Get message id error!'; exit 1; fi
if [[ ! "${MESSAGE_ID}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong message id!'; exit 1
fi

TIMESTAMP=$(TZ=utc date +%s)

ISSUER='src/main/res/counts.bin'

if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(wc -c < "${ISSUER}")" -ne 8 ]]; then
 echo "File \"${ISSUER}\" size is not 8 bytes!"; exit 1
fi

COUNTER="$(xxd -p -c 8 "${ISSUER}")"
COUNT=$((16#${COUNTER:0:8} + 1))
COUNTER=$((16#${COUNTER:8:8} + 1))
IMAGE_ID="$(printf '%08x%08x' $TIMESTAMP $COUNTER)"

ISSUER="src/main/res/${IMAGE_ID}.jpg"
if test -f "${ISSUER}"; then
 echo "File \"${ISSUER}\" exists!"; exit 1; fi

cp "/tmp/file_${NEW_FILE_ID}.img" "${ISSUER}"
if test $? -ne 0; then
 echo 'Copy error!'; exit 1
elif [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 1
fi

ISSUER='src/main/res/counts.bin'
printf '%08x%08x' $COUNT $COUNTER | xxd -p -r > "${ISSUER}"

if test $? -ne 0; then
 echo 'Counts error!'; exit 1; fi

ISSUER='src/main/res/db.bin'
printf '%08x%08x' $TIMESTAMP $COUNTER | xxd -p -r >> "${ISSUER}"

if test $? -ne 0; then
 echo 'Database error!'; exit 1; fi

mv "${IDS_TMP_FILE}" "${IDS_FILE}"
if test $? -ne 0; then
 echo 'Ids error!'; exit 1; fi

git add . && git commit -m "new img ${IMAGE_ID}.jpg"

if test $? -ne 0; then
 echo 'Commit error!'; exit 1; fi
