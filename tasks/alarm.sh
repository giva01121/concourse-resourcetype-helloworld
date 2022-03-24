#!/bin/bash
set -euo pipefail
TEST_MODE=${TEST_MODE:=false}
DEBUG_MODE=${DEBUG_MODE:=false}
test "${TEST_MODE}" = "true" && echo "Script is running with TEST_MODE=true"
test "${DEBUG_MODE}" = "true" && set -x
#
priority="$1"
message="$2"
description="$3"
alias="${4:-}"

BUILD_NUMBER=$(cat  meta/build-name)
JOB_NAME=$(cat  meta/build-job-name)
PIPELINE_NAME=$(cat  meta/build-pipeline-name)
TEAM_NAME=$(cat  meta/build-team-name)
ATC_EXTERNAL_URL=$(cat  meta/atc-external-url)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PIPELINE_URL="${ATC_EXTERNAL_URL}/teams/${TEAM_NAME}/pipelines/$PIPELINE_NAME/jobs/$JOB_NAME/builds/$BUILD_NUMBER"
body_template=$SCRIPT_DIR/body_template.json

# Please input PRIORITY, MESSAGE, DESCRIPTION as mandatory params. ALIAS is an optional parameter
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ];then
  echo 'Please provide $1=priority $2=message $3=description'
  exit 1
fi

jq --arg priority "$priority"  '.priority = $priority' < $body_template > body-parsed.json
jq --arg message "$message"  '.message = $message' <  body-parsed.json > INPUT.tmp && mv INPUT.tmp body-parsed.json
jq --arg description "$description" \
   --arg pipeline_url "$PIPELINE_URL" \
   '.description = $description +" The pipeline url is: "+ $pipeline_url' < body-parsed.json > INPUT.tmp && mv INPUT.tmp body-parsed.json
if [ -n "${alias}" ];then
  jq --arg 'alias' "$alias" '.alias = $alias' < body-parsed.json > INPUT.tmp && mv INPUT.tmp body-parsed.json
fi

if [ "${TEST_MODE}" = "true" ]; then
  echo "TEST_MODE - OpsGenie alert: $(cat body-parsed.json)"
else
  test "${DEBUG_MODE}" = "true" && set +x # prevent to log genie_key
  curl -X POST https://api.eu.opsgenie.com/v2/alerts \
       -H "Content-Type: application/json"         \
       -H "Authorization: GenieKey ${genie_key}" \
       -d @body-parsed.json
fi
