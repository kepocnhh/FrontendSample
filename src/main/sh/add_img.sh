#!/usr/local/bin/bash

TIMESTAMP=$(TZ=utc date +%s)

ISSUER='src/main/res/counts.bin'

if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

COUNTER="$(xxd -p -c 8 "${ISSUER}")"
COUNT=$((16#${COUNTER:0:8} + 1))
COUNTER=$((16#${COUNTER:8:8} + 1))
IMAGE_ID="$(printf '%08x%08x' $TIMESTAMP $COUNTER)"

ISSUER="src/main/res/${IMAGE_ID}.jpg"
CODE=$(curl -m 8 -w '%{http_code}' -o "${ISSUER}" 'https://cataas.com/cat')

if test $? -ne 0; then
 echo 'Curl error!'; exit 1; fi

if [[ "${CODE}" != '200' ]]; then
 echo 'Get img error!'; exit 1; fi

if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

if [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
 echo "File \"${ISSUER}\" is not jpg!"; exit 1; fi

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
