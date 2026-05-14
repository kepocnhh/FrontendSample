#!/usr/local/bin/bash

if test $# -ne 4; then
 echo 'Wrong arguments!' >&2; exit 1; fi

BS_INPUT="$1"
if test -z "${BS_INPUT}"; then
 echo 'Argument BS_INPUT is empty!' >&2; exit 1; fi

BS_BLOCKS="$2"
if [[ ! "${BS_BLOCKS}" =~ ^[1-9][0-9]*$ ]]; then
 echo 'Wrong blocks!' >&2; exit 1
elif test $BS_BLOCKS -gt 128; then
 echo "${BS_BLOCKS} is not supported!" >&2; exit 1
fi

BS_TARGET_HEX="$3"
if test "${#BS_TARGET_HEX}" -ne $((BS_BLOCKS * 2)); then
 echo 'Wrong target hex!' >&2; exit 1; fi

BS_LOCALE="$4"
FOUND='false'
EXPECTED=('C')
for it in "${EXPECTED[@]}"; do
 if test "${BS_LOCALE}" == "$it"; then
  FOUND='true'; break; fi
done
if test "${FOUND}" != 'true'; then
 echo "Locale \"${BS_LOCALE}\" is not supported!" >&2; exit 1; fi
LC_ALL="${BS_LOCALE}"

if [[ ! -f "${BS_INPUT}" ]] || [[ ! -s "${BS_INPUT}" ]]; then
 echo '-1'; exit 0; fi

BS_BLOCKS_SIZE="$(wc -c < "${BS_INPUT}")"
if [[ "${BS_BLOCKS_SIZE}" -ne 0 && $((BS_BLOCKS_SIZE % BS_BLOCKS)) -ne 0 ]]; then
 echo "File \"${BS_INPUT}\" size is not multiple of ${BS_BLOCKS} bytes!" >&2; exit 1; fi
LOW=0
HIGH=$((BS_BLOCKS_SIZE / BS_BLOCKS - 1))
FOUND_INDEX=-1
while [ $LOW -le $HIGH ]; do
 MID=$(((LOW + HIGH) / 2))
 CURRENT_HEX=$(dd if="${BS_INPUT}" bs=$BS_BLOCKS count=1 skip=$MID 2>/dev/null | xxd -p | tr -d '\n')
 if test "${CURRENT_HEX}" == "${BS_TARGET_HEX}"; then
  FOUND_INDEX=$MID; break
 elif [[ "${CURRENT_HEX}" < "${BS_TARGET_HEX}" ]]; then
  LOW=$((MID + 1)); else
  HIGH=$((MID - 1)); fi
done

echo "${FOUND_INDEX}"
