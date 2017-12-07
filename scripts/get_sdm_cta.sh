#!/bin/bash

#PBS -W group_list=bhurwitz
#PBS -q windfall
#PBS -l select=1:ncpus=4:mem=8gb
#PBS -l pvmem=7gb
#PBS -l place=free:shared
#PBS -l walltime=200:00:00
#PBS -l cput=200:00:00
#PBS -M jamesthornton@email.arizona.edu
#PBS -m bea

#LOAD R
module load R

#MOVE INTO DIRECTORY CONTAINING OBSERVATIONS
cd $FILE_DIR

#STORE ALL OBSERVATIONS FILES INTO LIST
#ls *.csv > list

LIST="list${PBS_ARRAY_INDEX}"

#FOR OBSERVATION FILE IN LIST, RUN SDM TO GENERATE MAPS
for file in $(cat $LIST); do
 
  ID=$(basename $file | cut -d '-' -f 1)
  
  mkdir -p $OUT_DIR/$ID/CTA/  
  $SCRIPT_DIR/run-sdm-algo.R $file $ID $OUT_DIR/$ID/CTA CTA 1
  $SCRIPT_DIR/run-sdm-algo.R $file $ID $OUT_DIR/$ID/CTA CTA 10
  $SCRIPT_DIR/run-sdm-algo.R $file $ID $OUT_DIR/$ID/CTA CTA 50 

  cd $OUT_DIR/$ID
  tar -zcvf $ID.CTA.tar.gz CTA
  rm -rf CTA  

done

echo "Completed CTA SDMS for $ID"

