#!/bin/bash

# Your job will use 1 node, 1 core, and 1gb of memory total.
#PBS -q windfall
#PBS -l select=1:ncpus=1:mem=6gb:pcmem=6gb

### Request email when job begins and ends - commented out in this case
#PBS -m bea

### Specify email address to use for notification - commented out in this case
#PBS -M dtruong@email.arizona.edu

### Specify a name for the job
#PBS -N stack_sdm

### Specify the group name
#PBS -W group_list=nirav

### Used if job requires partial node only
#PBS -l place=pack:shared

### CPUtime required in hhh:mm:ss.
### Leading 0's can be omitted e.g 48:0:0 sets 48 hours
#PBS -l cput=72:00:00

### Walltime is created by cputime divided by total cores.
### This field can be overwritten by a longer time
#PBS -l walltime=72:00:00

### Joins standard error and standard out
#PBS -j oe

### Load modules
module load R

### Change directory
cd $(dirname $SCRIPT_DIR)

### Job

# Compute range of species to work on
SDM_DIRS=($INPUT/*)
TOTAL_DIRS=${#SDM_DIRS[@]}
CHUNK_SIZE=$(( $TOTAL_DIRS / $NUM_WORKERS_PER ))
START=$(( CHUNK_SIZE *  $WORKER_NUM ))
END=$(( $START + ($CHUNK_SIZE - 1) ))

# Initialize Directories
if [[ ! -d $OUTPUT/$ALGORITHM/ ]]; then
	mkdir $OUTPUT/$ALGORITHM/
fi

if [[ ! -d $OUTPUT/$ALGORITHM/$REPLICATE/ ]]; then
	mkdir $OUTPUT/$ALGORITHM/$REPLICATE/
fi

if [[ ! -d $OUTPUT/$ALGORITHM/$REPLICATE/ ]]; then
	mkdir $OUTPUT/$ALGORITHM/$REPLICATE/
fi

if [[ ! -d  $OUTPUT/$ALGORITHM/$REPLICATE/raw/ ]]; then
	mkdir $OUTPUT/$ALGORITHM/$REPLICATE/raw/
fi

if [[ ! -d $OUTPUT/$ALGORITHM/$REPLICATE/raw/node$WORKER_NUM ]]; then
	mkdir $OUTPUT/$ALGORITHM/$REPLICATE/raw/node$WORKER_NUM
fi

if [[ ! -d $OUTPUT/$ALGORITHM/$REPLICATE/intermediate ]]; then
	mkdir $OUTPUT/$ALGORITHM/$REPLICATE/intermediate
fi

# Aggregate Raster files
bash $SCRIPT_DIR/aggregate_rasters.sh -a $ALGORITHM -r $REPLICATE -s $START -e $END -i $INPUT -o $OUTPUT/$ALGORITHM/$REPLICATE/raw/node$WORKER_NUM/

# Grab one of the remainders, if there is one left
if [[ $WORKER_NUM -lt $(( $TOTAL_DIRS % $NUM_WORKERS_PER )) ]]; then
	REMAIN_INDEX=$(( ($CHUNK_SIZE * $NUM_WORKERS_PER) + $WORKER_NUM ))
	bash $SCRIPT_DIR/aggregate_rasters.sh -a $ALGORITHM -r $REPLICATE -s $REMAIN_INDEX -e $REMAIN_INDEX -i $INPUT -o $OUTPUT/$ALGORITHM/$REPLICATE/raw/node$WORKER_NUM/
fi

# Run stack-sdm script and remove unneeded png files
Rscript $SCRIPT_DIR/stack-sdms.R $OUTPUT/$ALGORITHM/$REPLICATE/raw/node$WORKER_NUM/ node$WORKER_NUM-$ALGORITHM-bg$REPLICATE $OUTPUT/$ALGORITHM/$REPLICATE/intermediate
rm $OUTPUT/$ALGORITHM/$REPLICATE/intermediate/*.png

# Increment number of finished nodes
COUNT_PATH=$SCRIPT_DIR/resources/$ALGORITHM-$REPLICATE-finished.count
COUNT=$(flock -e $SCRIPT_DIR/resources/stack.lock echo $(( $(cat $COUNT_PATH) + 1 )) > $COUNT_PATH; cat $COUNT_PATH)

# If last worker done, then do second pass to combine intermediate stacks
if [[ $COUNT == $NUM_WORKERS_PER ]]; then
	Rscript $SCRIPT_DIR/stack-sdms.R $OUTPUT/$ALGORITHM/$REPLICATE/intermediate final-$ALGORITHM-bg$REPLICATE $OUTPUT/$ALGORITHM/$REPLICATE/
fi

# Otherwise die down