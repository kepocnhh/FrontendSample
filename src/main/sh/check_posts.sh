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

ISSUER='src/main/res/pending.bin'

POST_SIZE=8
PENDING_SIZE=$((PENDING_COUNT * POST_SIZE))
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

echo 'Not implemented!'; exit 1 # todo
