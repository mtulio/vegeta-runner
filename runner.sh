#!/bin/bash

# Vegetta Runner load test

set -e
set -x
ulimit -u 65535
ulimit -n 65535
set +x

PLAN_FILE=$1
VEGETA_EXTRA_ARGS="-keepalive -http2=f -header=\"Content-type:gzip\""
VEGETA_BIN=${2:-./bin/vegeta}
VEGETA_OUTPUT_REPORTS=()

PATH_INPUT=${3:-input/}
PATH_OUTPUT=${4:-output/}

#########################
# Common
#########################

function _echo() {
  echo "[$(date)] $1"
}

#########################
# Vegeta Plan
#########################
function run_plan(){
  PLAN_RATE=$1
  PLAN_NAME_LABEL_RATE=${PLAN_NAME_LABEL}-${PLAN_RATE}rps
  TIMESTAMP=$(date +%s)
  _echo "# System Limits: ofiles-n[$(ulimit -n)] uproc-u[$(ulimit -u)]"

  set -x
  ${VEGETA_BIN} attack \
    -keepalive \
    -http2=f \
    -header="User-Agent:vegeta-${PLAN_NAME_LABEL}" \
    -header="Accept-Encoding:gzip" \
    -targets=${PATH_INPUT}${PLAN_INPUT} \
    -duration=${PLAN_TEST_DURATION} \
    -rate=${PLAN_RATE} \
    > ${PATH_OUTPUT}${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin
  set +x
  if [[ -f ${PATH_OUTPUT}${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin ]]; then
    _echo "Results are saved on file: ${PATH_OUTPUT}${PLAN_NAME_LABEL_RATE}.bin"
    VEGETA_OUTPUT_REPORTS+=${PATH_OUTPUT}${PLAN_NAME_LABEL_RATE}-${TIMESTAMP}.bin
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
  for f in $(ls ${PATH_OUTPUT}${PLAN_NAME_LABEL}*.bin); do
    if [[ $OUT_FILES == "" ]]; then
      OUT_FILES="${f}"
    else
      OUT_FILES+=",${f}"
    fi
  done

  _echo "#> Creating JSON report in ${PATH_OUTPUT}${PLAN_NAME}.json"
  ${VEGETA_BIN} report --type=json --output output/${PLAN_NAME}.json ${PATH_OUTPUT}${PLAN_NAME_LABEL}*.bin

  _echo "#> Creating Text report in ${PATH_OUTPUT}${PLAN_NAME}.txt"
  ${VEGETA_BIN} report --type=text --output output/${PLAN_NAME}.txt ${PATH_OUTPUT}${PLAN_NAME_LABEL}*.bin

  _echo "#> Creating HTML report in ${PATH_OUTPUT}${PLAN_NAME}.html"
  ${VEGETA_BIN} report --type=hdrplot --output output/${PLAN_NAME}.html ${PATH_OUTPUT}${PLAN_NAME_LABEL}*.bin

  _echo "#> Creating JSON report in ${PATH_OUTPUT}${PLAN_NAME}-hist.txt"
  ${VEGETA_BIN} report \
    --type='hist[0,10ms,100ms,200ms,300ms,400ms,500ms,1s,2s,10s,30s,60s]' \
    --output output/${PLAN_NAME}-hist.txt \
    ${PATH_OUTPUT}${PLAN_NAME_LABEL}*.bin


#########################
# Main
#########################

_echo "# Parsing plan file $PLAN_FILE"
while read line; do
  if [[ $line == "#"* ]]; then continue; fi
  if [[ $line =~ ^""$ ]]; then continue; fi
  setup_plan "$line"
done < $PLAN_FILE
