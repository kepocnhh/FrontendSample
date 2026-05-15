#!/usr/local/bin/bash

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
PENDING_COUNT=$((16#${COUNTS:8:8}))
COUNTER=$((16#${COUNTS:16:8}))

if test ${PENDING_COUNT} -eq 0; then
 echo "No pending posts"; exit 0; fi

echo 'Not implemented!'; exit 1 # todo
