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
VEGETA_OUTPUT_REPORTS=()

#########################
# Vegeta Plan
#########################
function run_plan(){
  PLAN_RATE=$1
  PLAN_NAME_LABEL=${PLAN_NAME}-${PLAN_TEST_DURATION}-${PLAN_RATE}rps

  set -x
  ${VEGETA_BIN} attack \
    -keepalive \
    -http2=f \
    -header="User-Agent:vegeta-${PLAN_NAME_LABEL}" \
    -targets=input/${PLAN_INPUT} \
    -duration=${PLAN_TEST_DURATION} \
    -rate=${PLAN_RATE} \
    > output/${PLAN_NAME_LABEL}.bin
  set +x
  if [[ -f output/${PLAN_NAME_LABEL}.bin ]]; then
    echo "Results are saved on file: output/${PLAN_NAME_LABEL}.bin"
    VEGETA_OUTPUT_REPORTS+=output/${PLAN_NAME_LABEL}.bin
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
  #run_report $PLAN_NAME
}

#########################
# Vegeta Report
#########################

function run_report(){
  # Sample to run
  #./bin/vegeta report \
  #  -inputs=output/test-azure-60s-17rps.bin,output/test-azure-60s-36rps.bin \
  #  -reporter=plot > output/test-azure.html

  echo "run_report()"

  OUT_FILES=""
  echo $OUT_FILES
  echo ${VEGETA_OUTPUT_REPORTS[@]}
  for i in ${VEGETA_OUTPUT_REPORTS[@]}; do
    echo $OUT_FILES
    OUT_FILES="$OUT_FILES,$i"
  done
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=json > output/${PLAN_NAME}.json
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=txt > output/${PLAN_NAME}.txt
  ${VEGETA_BIN} report -inputs=${OUT_FILES} -reporter=plt > output/${PLAN_NAME}.plt
}


#########################
# Main
#########################

echo "# Parsing plan file $PLAN_FILE"
while read line; do
  echo $line
  if [[ $line == "#"* ]]; then continue; fi
  setup_plan "$line"
done < $PLAN_FILE
