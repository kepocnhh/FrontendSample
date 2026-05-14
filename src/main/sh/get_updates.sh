#!/usr/local/bin/bash

SCRIPTS=(
 './src/main/sh/on_channel_post.sh'
 './src/main/sh/tg_get_channel_posts.sh'
 './src/main/sh/commit_img.sh'
)
for (( INDEX=0; INDEX<${#SCRIPTS[@]}; INDEX++ )); do
 ISSUER="${SCRIPTS[INDEX]}"
 if [[ ! -f "${ISSUER}" ]]; then
  echo "No file \"${ISSUER}\"!"; exit 1
 elif [[ ! -s "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is empty!"; exit 1
 elif [[ ! -x "${ISSUER}" ]]; then
  echo "File \"${ISSUER}\" is not executable!"; exit 1
 fi
done

ARGUMENTS=(TG_CHANNEL_ID)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"${ARGUMENT}\" is empty!"; exit 1; fi
done

if [[ ! "${TG_CHANNEL_ID}" =~ ^-?[1-9][0-9]*$ ]]; then
 echo 'Wrong channel id!'; exit 1; fi

ISSUER='/tmp/updates.json'
rm "${ISSUER}"
./src/main/sh/tg_get_channel_posts.sh "${ISSUER}" || exit 1

TG_UPDATES="$(cat "${ISSUER}")"

RESULT_LENGTH="$(printf '%s' "${TG_UPDATES}" | yq -p=json -er '.result | length')"
if test "${RESULT_LENGTH}" == '0'; then
 echo 'No results'; exit 0
elif [[ ! "${RESULT_LENGTH}" =~ ^[1-9][0-9]*$ ]]; then
 echo "Wrong result length(${RESULT_LENGTH})!"; exit 1
fi

for (( INDEX=0; INDEX<RESULT_LENGTH; INDEX++ )); do
 CHANNEL_POST="$(printf '%s' "${TG_UPDATES}" | yq -p=json -o=json ".result[$INDEX].channel_post // null")"
 if test "${CHANNEL_POST}" == 'null'; then
  echo 'No channel post'; continue; fi
 ACTUAL_CHANNEL_ID="$(printf '%s' "${CHANNEL_POST}" | yq -p=json -r ".chat.id // null")"
 if test "${ACTUAL_CHANNEL_ID}" != "${TG_CHANNEL_ID}"; then
  echo 'Ignoring channel'; continue; fi
 ./src/main/sh/on_channel_post.sh "${CHANNEL_POST}" "${INDEX}"; CODE=$?
 if test "${CODE}" == '204'; then continue
 elif test "${CODE}" != '0'; then exit 1; fi
 ./src/main/sh/commit_img.sh "${INDEX}" || exit 1
done
