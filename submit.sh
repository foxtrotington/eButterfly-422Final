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

#Generate SDM from observation data (CTA)
JOB1=`qsub -J 1-101 -v SCRIPT_DIR,FILE_DIR,OUT_DIR -N Get_SDM -e "$STDERR_DIR" -o "$STDOUT_DIR" $SCRIPT_DIR/get_sdm_cta.sh`

#Generate SDM from observation data (GLM)
JOB2=`qsub -J 1-101 -v SCRIPT_DIR,FILE_DIR,OUT_DIR -N Get_SDM -e "$STDERR_DIR" -o "$STDOUT_DIR" $SCRIPT_DIR/get_sdm_glm.sh`

#Generate SDM from observation data (RF)
JOB3=`qsub -J 1-101 -v SCRIPT_DIR,FILE_DIR,OUT_DIR -N Get_SDM -e "$STDERR_DIR" -o "$STDOUT_DIR" $SCRIPT_DIR/get_sdm_rf.sh`
