#!/bin/bash

# Vegetta Runner load test

set -e
set -x
ulimit -s 65535 |true
ulimit -n 65535 |true
set +x

PLAN_FILE=$1
VEGETA_EXTRA_ARGS="-keepalive -http2=f -header=\"Content-type:gzip\""
VEGETA_BIN=${3:-./bin/vegeta}
VEGETA_OUTPUT_REPORTS=()

#########################
# Vegeta Plan
#########################
function run_plan(){
  PLAN_RATE=$1
  PLAN_NAME_LABEL_RATE=${PLAN_NAME_LABEL}-${PLAN_RATE}rps
  TIMESTAMP=$(date +%s)
  echo "# Limits: ofiles-n[$(ulimit -n)] uproc-u[$(ulimit -u)]"

  set -x
  ${VEGETA_BIN} attack \
    -keepalive \
    -http2=f \
    -header="User-Agent:vegeta-${PLAN_NAME_LABEL}" \
    -header="Accept-Encoding:gzip" \
    -targets=input/${PLAN_INPUT} \
    -duration=${PLAN_TEST_DURATION} \
    -rate=${PLAN_RATE} \
    > output/${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin
  set +x
  if [[ -f output/${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin ]]; then
    echo "Results are saved on file: output/${PLAN_NAME_LABEL_RATE}.bin"
    VEGETA_OUTPUT_REPORTS+=output/${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin
  fi
}

function setup_plan(){
  PLAN_NAME=$(echo $line |awk -F';' '{print$1}')
  PLAN_INPUT=$(echo $line |awk -F';' '{print$2}')
  PLAN_TEST_RATES=$(echo $line |awk -F';' '{print$3}')
  PLAN_TEST_DURATION=$(echo $line |awk -F';' '{print$4}')
  PLAN_TIME_WAIT=$(echo $line |awk -F';' '{print$5}')
  PLAN_NAME_LABEL=${PLAN_NAME}-${PLAN_TEST_DURATION}

  OIFS=$IFS
  IFS=','
  for T_RATE in $PLAN_TEST_RATES; do
    run_plan $T_RATE
  done
  IFS=$OIFS
  run_report
}

#########################
# Vegeta Report
#########################

function run_report(){

  OUT_FILES=""
  for f in $(ls output/${PLAN_NAME_LABEL}*.bin); do
    if [[ $OUT_FILES == "" ]]; then
      OUT_FILES="${f}"
    else
      OUT_FILES+=",${f}"
    fi
  done

  echo "#> Creating JSON report in output/${PLAN_NAME}.json"
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=json > output/${PLAN_NAME}.json

  echo "#> Creating Text report in output/${PLAN_NAME}.txt"
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=text > output/${PLAN_NAME}.txt

  echo "#> Creating HTML report in output/${PLAN_NAME}.html"
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=plot > output/${PLAN_NAME}.html

  echo "#> Creating JSON report in output/${PLAN_NAME}-hist.txt"
  ${VEGETA_BIN} report -inputs=${OUT_FILES} \
    -reporter='hist[0,10ms,100ms,200ms,300ms,400ms,500ms,1s,2s,10s,30s,60s]' > output/${PLAN_NAME}-hist.txt
}


#########################
# Main
#########################

echo "# Parsing plan file $PLAN_FILE"
while read line; do
  if [[ $line == "#"* ]]; then continue; fi
  if [[ $line =~ ^""$ ]]; then continue; fi
  setup_plan "$line"
done < $PLAN_FILE
