#!/bin/bash

# VARIABLE DEFINITIONS
ALGORITHM_LIST=( CTA RF GLM )
REPLICATE_LIST=( 1 10 50 )

# FUNCTION DEFINITIONS
print_usage() {
	echo "Usage: ./scripts/$0 <script_dir> <num_workers>"
	echo -e "\tscript_dir - directory path of scripts"
	echo -e "\tnum_workers - the number of workers to spawn per algorithm/replicate combination"
}

# PARSE ARGUMENTS
if [[ $# -lt 4 ]]; then
	echo "Missing arguments"
	print_usage
	exit 1
fi

SCRIPT_DIR=${1%/}
if [[ ! -e $SCRIPT_DIR || ! -d $SCRIPT_DIR ]]; then
	echo "Invalid scripts directory"
	print_usage
	exit 1
fi

NUM_WORKERS_PER=$2
if [[ $NUM_WORKERS_PER -lt 1 ]]; then
	echo "Invalid number of workers"
	print_usage
	exit 1
fi

INPUT=${3%/}
if [[ ! -e $INPUT || ! -d $INPUT ]]; then
	echo "Invalid input directory"
	print_usage
	exit 1
fi

OUTPUT=${4%/}
if [[ ! -e $OUTPUT || ! -d $OUTPUT ]]; then
	echo "Invalid output directory"
	print_usage
	exit 1
fi

#INSTANTIATE LOCK FILE
if [[ ! -d $SCRIPT_DIR/resources/ ]]; then
	mkdir $SCRIPT_DIR/resources/
fi

if [[ ! -f $SCRIPT_DIR/resources/stack.lock ]]; then
	touch $SCRIPT_DIR/resources/stack.lock
fi

for ALGORITHM in ${ALGORITHM_LIST[@]}; do
	for REPLICATE in ${REPLICATE_LIST[@]}; do
		#INSTANTIATE COUNT FILE
		echo 0 > $SCRIPT_DIR/resources/$ALGORITHM-$REPLICATE-finished.count
		for (( WORKER_NUM = 0; i < NUM_WORKERS_PER; i++ )); do
			qsub -v ALGORITHM,REPLICATE,INPUT,OUTPUT,WORKER_NUM,NUM_WORKERS_PER,SCRIPT_DIR pbs_stack_sdm.sh
		done
	done
done





