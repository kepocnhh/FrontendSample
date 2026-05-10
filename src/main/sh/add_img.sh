#!/usr/local/bin/bash

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
TRY_NUMBER=0
MAX_TRIES=8
while true; do
 TRY_NUMBER=$((TRY_NUMBER + 1))
 if [[ $TRY_NUMBER -gt $MAX_TRIES ]]; then
  echo 'Final try error!'; exit 1; fi
 rm "${ISSUER}"
 CODE=$(curl -m 8 -w '%{http_code}' -o "${ISSUER}" 'https://cataas.com/cat')
 if test $? -ne 0; then
  echo 'Curl error!'; continue
 elif [[ "${CODE}" != '200' ]]; then
  echo 'Get img error!'; continue
 elif [[ ! -f "${ISSUER}" ]]; then
  echo "No file \"${ISSUER}\"!"; continue
 elif [[ ! -s "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is empty!"; continue
 elif [[ "$(file --mime-type -b "${ISSUER}")" != 'image/jpeg' ]]; then
  echo "File \"${ISSUER}\" is not jpg!"; continue
 fi
 break
done

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
