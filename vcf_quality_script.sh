#! /bin/bash

date

directory=$1


for x in $(ls $directory)
do
  if [[ $x == *.vcf.gz ]] 
  then
  name="$(basename "$x" .vcf.gz)"
  bcftools filter -i 'QUAL>30 && DP>10' $x -o ./filteredvcf/${name}filtered.vcf
  sleep 5
  else 
  echo $x is not a vcf
  fi
done

echo "DONE"

#activate bcftools before using