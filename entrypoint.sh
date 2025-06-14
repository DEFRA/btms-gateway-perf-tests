#!/bin/sh

echo "run_id: $RUN_ID in $ENVIRONMENT"

NOW=$(date +"%Y%m%d-%H%M%S")

if [ -z "${JM_HOME}" ]; then
  JM_HOME=/opt/perftest
fi

JM_SCENARIOS=${JM_HOME}/scenarios
JM_SCRIPTS=${JM_HOME}/scripts
JM_REPORTS=${JM_HOME}/reports
JM_LOGS=${JM_HOME}/logs

rm -rf "${JM_REPORTS:?}/"*
rm -rf "${JM_LOGS:?}/"*

mkdir -p ${JM_REPORTS} ${JM_LOGS}

SCENARIOFILE=${JM_SCENARIOS}/${TEST_SCENARIO}.jmx
REPORTFILE=${NOW}-perftest-${TEST_SCENARIO}-report.csv
REPORTFILE2=${NOW}-perftest-log-report.csv
LOGFILENAME=perftest-${TEST_SCENARIO}.log
LOGFILE=${JM_LOGS}/${LOGFILENAME}

# === PROXY CONFIGURATION ===

JVM_PROXY_OPTS=""
PROXY_ENV="${HTTPS_PROXY:-$CDP_HTTPS_PROXY}"

if [ -n "$PROXY_ENV" ]; then
  echo "Detected HTTPS_PROXY"
  
  PROXY_URL="${PROXY_ENV#http://}"
  PROXY_URL="${PROXY_URL#https://}"

  if echo "$PROXY_URL" | grep -q '@'; then
    PROXY_AUTH="${PROXY_URL%@*}"
    PROXY_HOSTPORT="${PROXY_URL#*@}"

    PROXY_USER="${PROXY_AUTH%%:*}"
    PROXY_PASS="${PROXY_AUTH#*:}"
  else
    PROXY_HOSTPORT="$PROXY_URL"
    PROXY_USER=""
    PROXY_PASS=""
  fi

  PROXY_HOST="${PROXY_HOSTPORT%%:*}"
  PROXY_PORT="${PROXY_HOSTPORT#*:}"

  if [ "$PROXY_HOST" = "$PROXY_PORT" ]; then
    PROXY_PORT="443"
  fi

  echo "HTTPS_PROXY HOST: $PROXY_HOST" 

if [ -n "$PROXY_USER" ]; then
    JVM_PROXY_OPTS="-Dhttps.proxyHost=${PROXY_HOST} -Dhttps.proxyPort=${PROXY_PORT} -Dhttps.proxyUser=${PROXY_USER} -Dhttps.proxyPassword=${PROXY_PASS}"
  else
    JVM_PROXY_OPTS="-Dhttps.proxyHost=${PROXY_HOST} -Dhttps.proxyPort=${PROXY_PORT}"
  fi
fi

# Run the test suite
jmeter -Djava.net.useSystemProxies=true ${JVM_PROXY_OPTS} -n -t ${SCENARIOFILE} -e -l "${REPORTFILE}" -o ${JM_REPORTS} -f -Jenv="${ENVIRONMENT}" -JbaseDir="${JM_HOME}" -j ${LOGFILE} #-j /dev/stdout 
test_exit_code=$?

# Publish the results into S3 so they can be displayed in the CDP Portal
if [ -n "$RESULTS_OUTPUT_S3_PATH" ]; then
  # Copy the CSV report file and the generated report files to the S3 bucket
   if [ -f "$JM_REPORTS/index.html" ]; then
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$REPORTFILE" "$RESULTS_OUTPUT_S3_PATH/$REPORTFILE"
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$JM_REPORTS" "$RESULTS_OUTPUT_S3_PATH" --recursive
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$LOGFILE" "$RESULTS_OUTPUT_S3_PATH/$REPORTFILE2"
      if [ $? -eq 0 ]; then
        echo "CSV report file and test results published to $RESULTS_OUTPUT_S3_PATH"
      fi
   else
      echo "$JM_REPORTS/index.html is not found"
      exit 1
   fi
else
   echo "RESULTS_OUTPUT_S3_PATH is not set"
   exit 1
fi

exit $test_exit_code
