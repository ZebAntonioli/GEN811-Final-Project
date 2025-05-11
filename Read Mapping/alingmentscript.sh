#! /bin/bash

date

FW=$1
RV=$2

name="$(basename "$FW" | cut -d'_' -f1)"

bwa mem -t 24 GCF_023699985.2_Ovbor_1.2_genomic.fna $FW $RV > ./WholeGenomeFiles/$name.sam

sleep 5

echo "DONE"