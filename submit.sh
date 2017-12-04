#!/bin/bash

#GET AND CHECK VARIABLE DECLARATIONS
source ./settings.sh

if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "$SCRIPT_DIR does not exist. Job terminated."
    exit 1
fi

if [[ ! -d "$OUT_DIR" ]]; then
    echo "$OUT_DIR does not exist. Directory created for output."
    mkdir -p "$OUT_DIR"
fi

if [[ ! -d "$STDERR_DIR" ]]; then
    echo "$STDERR_DIR does not exist. Directory created for standard error."
    mkdir -p "$STDERR_DIR"
fi

if [[ ! -d "$STDOUT_DIR" ]]; then
    echo "$STDOUT_DIR does not exist. Directory created for standard out."
    mkdir -p "$STDOUT_DIR"
fi

#Generate SDM from observation data

JOB1=`qsub -v SCRIPT_DIR,FILE_DIR,OUT_DIR -N Get_SDM -e "$STDERR_DIR" -o "$STDOUT_DIR" $SCRIPT_DIR/get_sdm.sh`
