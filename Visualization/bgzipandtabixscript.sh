#! /bin/bash

date 

directory=$1

source activate ensembl-vep

for x in $(ls $directory)
do
  if [[ $x == *.vcf ]] 
  then
  name="$(basename "$x" .vcf)"
  bgzip $x
  else 
  echo $x is not a vcf
  sleep 5
  fi
done

for x in $(ls $directory)
do
  if [[ $x == *.vcf.gz ]] 
  then
  name="$(basename "$x" .vcf.gz)"
  tabix -p vcf $x
  else 
  echo $x is not a zipped vcf
  sleep 5
  fi
done

echo "DONE"