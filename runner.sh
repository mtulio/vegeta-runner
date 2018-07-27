#!/bin/bash

# Vegetta Runner load test

set -e
set -x
sudo ulimit -s 65535 |true
sudo ulimit -n 65535 |true
set +x

PLAN_FILE=$1
VEGETA_EXTRA_ARGS="-keepalive -http2=f -header=\"Content-type:gzip\""
VEGETA_BIN=${3:-./bin/vegeta}

function run_plan(){
  PLAN_RATE=$1
  PLAN_NAME_LABEL=${PLAN_NAME}-${PLAN_TEST_DURATION}-${PLAN_RATE}rps

  set -x
  ${VEGETA_BIN} attack \
    -keepalive \
    -http2=f \
    -header=\"Content-type:gzip\" \
    -targets=input/${PLAN_INPUT} \
    -duration=${PLAN_TEST_DURATION} \
    -rate=${PLAN_RATE} \
    > output/${PLAN_NAME_LABEL}.bin
  set +x
  if [[ -f output/${PLAN_NAME_LABEL}.bin ]]; then
    echo "Results are saved on file: output/${PLAN_NAME_LABEL}.bin"
  fi
}

function setup_plan(){
  PLAN_NAME=$(echo $line |awk -F';' '{print$1}')
  PLAN_INPUT=$(echo $line |awk -F';' '{print$2}')
  PLAN_TEST_RATES=$(echo $line |awk -F';' '{print$3}')
  PLAN_TEST_DURATION=$(echo $line |awk -F';' '{print$4}')
  PLAN_TIME_WAIT=$(echo $line |awk -F';' '{print$5}')

  OIFS=$IFS
  IFS=','
  for T_RATE in $PLAN_TEST_RATES; do
    run_plan $T_RATE
  done

}

echo "# Parsing plan file $PLAN_FILE"
while read line; do
  echo $line
  if [[ $line == "#"* ]]; then continue; fi
  setup_plan "$line"
done < $PLAN_FILE
