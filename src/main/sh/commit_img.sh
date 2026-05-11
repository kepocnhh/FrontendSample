#!/usr/local/bin/bash

if test $# -ne 1; then
 echo 'Wrong arguments!'; exit 1; fi

NEW_FILE="$1"

if [[ ! -f "${NEW_FILE}" ]]; then
 echo "No file \"${NEW_FILE}\"!"; exit 1
elif [[ ! -s "${NEW_FILE}" ]]; then
 echo "File \"${NEW_FILE}\" is empty!"; exit 1
elif [[ "$(file --mime-type -b "${NEW_FILE}")" != 'image/jpeg' ]]; then
 echo "File \"${NEW_FILE}\" is not jpg!"; exit 1
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
cp "${NEW_FILE}" "${ISSUER}"
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

git add . && git commit -m "new img ${IMAGE_ID}.jpg"

if test $? -ne 0; then
 echo 'Commit error!'; exit 1; fi
