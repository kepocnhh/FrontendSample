#!/usr/local/bin/bash

ISSUER='src/main/res/counts.bin'

COUNTS_SIZE=12
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(wc -c < "${ISSUER}")" -ne ${COUNTS_SIZE} ]]; then
 echo "File \"${ISSUER}\" size is not ${COUNTS_SIZE} bytes!"; exit 1
fi

COUNTS="$(xxd -p -c ${COUNTS_SIZE} "${ISSUER}")"
PUBLISHED_COUNT=$((16#${COUNTS:0:8}))
PENDING_COUNT=$((16#${COUNTS:8:8}))
COUNTER=$((16#${COUNTS:16:8}))

if test ${PENDING_COUNT} -eq 0; then
 echo "No pending posts"; exit 0; fi

POST_SIZE=8
PUBLISHED_SIZE=$((PUBLISHED_COUNT * POST_SIZE))
PENDING_SIZE=$((PENDING_COUNT * POST_SIZE))
ISSUER='src/main/res/pending.bin'
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
elif [[ "$(wc -c < "${ISSUER}")" -ne ${PENDING_SIZE} ]]; then
 echo "File \"${ISSUER}\" size is not ${PENDING_SIZE} bytes!"; exit 1
fi

POST_INDEX=$((RANDOM % PENDING_COUNT))

POST_ID=$(dd if="${ISSUER}" bs=${POST_SIZE} count=1 skip=${POST_INDEX} 2>/dev/null | xxd -p | tr -d '\n')
if test $? -ne 0; then
 echo "Read \"${ISSUER}\" error!"; exit 1
elif [[ ! "${POST_ID}" =~ ^[0-9a-f]{16}$ ]]; then
 echo 'Post id error!'; exit 1
fi

if test ${PENDING_COUNT} -eq 1; then
 : > "${ISSUER}"
 if test $? -ne 0; then
  echo "Clear \"${ISSUER}\" error!"; exit 1; fi
else
 if test ${POST_INDEX} -lt $((PENDING_COUNT - 1)); then
  dd if="${ISSUER}" bs=${POST_SIZE} skip=$((POST_INDEX + 1)) seek=${POST_INDEX} conv=notrunc of="${ISSUER}" 2>/dev/null
  if test $? -ne 0; then
   echo 'Move bytes error!'; exit 1; fi
 fi
 truncate -s $(((PENDING_COUNT - 1) * POST_SIZE)) "${ISSUER}"
 if test $? -ne 0; then
  echo 'Truncate bytes error!'; exit 1; fi
fi

ISSUER='src/main/res/published.bin'
printf '%s' "${POST_ID}" | xxd -p -r >> "${ISSUER}"
if test $? -ne 0; then
 echo "Write \"${ISSUER}\" error!"; exit 1; fi

ISSUER="src/main/res/${POST_ID}.json"
if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

JSON_BODY="$(cat "${ISSUER}")"
if test $? -ne 0; then
 echo "Read \"${ISSUER}\" error!"; exit 1; fi

PUBLISHED_TIME=$(TZ=utc date +%s)
if test $? -ne 0; then
 echo 'Get published time error!'; exit 1
elif [[ ! "${PUBLISHED_TIME}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong published time!'; exit 1
elif test ${PUBLISHED_TIME} -gt 4294967295; then
 echo 'Wrong published seconds!'; exit 1
fi

JSON_BODY="$(printf '%s' "${JSON_BODY}" | yq -M -p=json -o=json ".published_time=${PUBLISHED_TIME}")"

printf '%s' "${JSON_BODY}" > "${ISSUER}"
if test $? -ne 0; then
 echo "Write \"${ISSUER}\" error!"; exit 1; fi

ISSUER='src/main/res/counts.bin'
printf '%08x%08x%08x' $((PUBLISHED_COUNT + 1)) $((PENDING_COUNT - 1)) ${COUNTER} | xxd -p -r > "${ISSUER}"
if test $? -ne 0; then
 echo "Write \"${ISSUER}\" error!"; exit 1; fi

ISSUER='src/main/res/pending.bin'
if [[ "$(wc -c < "${ISSUER}")" -ne $((PENDING_SIZE - POST_SIZE)) ]]; then
 echo "File \"${ISSUER}\" size is not $((PENDING_SIZE - POST_SIZE)) bytes!"; exit 1; fi

ISSUER='src/main/res/published.bin'
if [[ "$(wc -c < "${ISSUER}")" -ne $((PUBLISHED_SIZE + POST_SIZE)) ]]; then
 echo "File \"${ISSUER}\" size is not $((PUBLISHED_SIZE + POST_SIZE)) bytes!"; exit 1; fi

#

git add .

if test $? -ne 0; then
 echo 'Git add error!'; exit 1; fi

git commit -m "Post \"${POST_ID}\" was published."

if test $? -ne 0; then
 echo 'Git commit error!'; exit 1; fi
