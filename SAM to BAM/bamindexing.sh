#! /bin/bash

date

directory=$1
source activate samtools-1.20

for x in $(ls $directory)
do
  if [[ $x == *.bam ]] 
  then
  samtools index $x
  else 
  echo $x is not a bam
  fi
done

sleep 5

date

echo "DONE"