#! /bin/bash

date

directory=$1
reffasta=$2
source activate bcftools-1.21

for x in "$directory"/*.bam; do
  if [[ -f $x ]]; then
  name="$(basename "$x" .bam)" 
  echo "Processing $name"
  bcftools mpileup --threads 25 -f $reffasta $x | bcftools call -mv -o ${name}whole_genome_qcfilter_variants.vcf
  sleep 5
  else 
  echo $x is not a bam
  fi
done

sleep 5

mkdir -p ~/vcfWholeGenomeqcfiltersDeer
mv *.vcf ~/vcfWholeGenomeqcfiltersDeer/

date

echo "DONE"

