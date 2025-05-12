#! /bin/bash

date 

directory=$1

source activate ensembl-vep

for x in $(ls $directory)
do
  if [[ $x == *.vcf.gz ]] 
  then
  name="$(basename "$x" .vcf.gz)"
  vep -i $x --fasta GCF_023699985.2_Ovbor_1.2_genomic.fna.gz --gff GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz --vcf -o ${name}.vcf
  else 
  echo $x is not a zipped vcf
  sleep 5
  fi
done

sleep 5

echo "DONE