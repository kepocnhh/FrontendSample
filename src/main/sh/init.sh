#!/usr/local/bin/bash

ARGUMENTS=(VCS_PAT REPOSITORY_OWNER REPOSITORY_NAME REMOTE_BRANCH)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"$ARGUMENT\" is empty!"; exit $((100+INDEX)); fi
done

VCS_URL="https://${VCS_PAT}@github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
LOCAL_BRANCH=$(echo -n "${REMOTE_BRANCH}" | openssl dgst -sha256 -binary | xxd -p -c 32)
LOCAL_BRANCH="${LOCAL_BRANCH:0:8}"

git init \
 && git remote add origin "${VCS_URL}" \
 && git fetch origin "${REMOTE_BRANCH}" \
 && git checkout -b "${LOCAL_BRANCH}" FETCH_HEAD

if test $? -ne 0; then
 echo 'Git init error!'; exit 1; fi
