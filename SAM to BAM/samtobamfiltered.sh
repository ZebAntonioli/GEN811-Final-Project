#! /bin/bash

date

directory=$1
source activate samtools-1.20

for x in $(ls $directory)
do
  if [[ $x == *.sam ]] 
  then
  name="$(basename "$x" .sam)"
  samtools view -@ 40 -Sb -F 2308 $x | samtools sort -@ 40 -o ${name}_sorted_mapped_filtered.bam
  sleep 5
  else 
  echo $x is not a sam
  fi
done

mkdir ~/WholeGenomeFilteredBamFiles

mv *.bam ~/WholeGenomeFilteredBamFiles

date

echo "DONE"
#this script will remove unmapped, secondary, and supplementary reads as a result of the -F 2308