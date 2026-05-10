#!/usr/local/bin/bash

ARGUMENTS=(VCS_PAT)
for (( INDEX=0; INDEX<${#ARGUMENTS[@]}; INDEX++ )); do
 ARGUMENT="${ARGUMENTS[INDEX]}"
 if test -z "${!ARGUMENT}"; then
  echo "Argument \"$ARGUMENT\" is empty!"; exit $((100+INDEX)); fi
done

VCS_API='https://api.github.com'

ISSUER='/tmp/gh-user.json'
CODE=$(curl -m 8 -w '%{http_code}' -o "${ISSUER}" \
 -H "Authorization: token ${VCS_PAT}" \
 "${VCS_API}/user")

if test $? -ne 0; then
 echo 'Curl error!'; exit 1; fi

if [[ "${CODE}" != '200' ]]; then
 echo 'Get user error!'; exit 1; fi

if [[ ! -f "${ISSUER}" ]]; then
 echo "No file \"${ISSUER}\"!"; exit 1
elif [[ ! -s "${ISSUER}" ]]; then
 echo "File \"${ISSUER}\" is empty!"; exit 1
fi

USER_NAME="$(yq -erM '.name // .login' "${ISSUER}")" || exit 1
USER_ID="$(yq -erM .id "${ISSUER}")" || exit 1
USER_LOGIN="$(yq -erM .login "${ISSUER}")" || exit 1
USER_EMAIL="${USER_ID}+${USER_LOGIN}@users.noreply.github.com"

git config user.name "${USER_NAME}" \
 && git config user.email "${USER_EMAIL}"

if test $? -ne 0; then
 echo 'Git config error!'; exit 1; fi
