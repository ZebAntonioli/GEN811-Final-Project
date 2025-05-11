# GEN811-Final-Project
Final project for bioinformatics lab looking into genetic variant analysis of whitetail deer on Martha's Vineyard

# Background Information
This project is investigating a potential X-linked disorder in *Odocoileus virginianus* or whitetail deer (or white-tailed deer). 

# Pipeline Overview
* Obtain Reads
* Trim the reads with Trimmomatic
* Readmapping to the reference genome with Burrows-Wheeler Alignment tool
* Converting the SAM files into BAM files with Samtools
* Variant calling from the BAM files compared to the reference genome with bcftools
* Variant effect predictions from the resulting VCF files using esembl-VEP
* Filtering variants that are unique to the affected group compared to the control group
* Visualizing the varaints of interest in a genome browser

# Obtaining Reads
Using the `wget` command and the URL provided by the HCGS, the untrimmed `fastq.gz` files were retrieived and imported into my home directory. 
```
wget "example_url"
```

# Trimming
Trimming was done with the use of `trimmomatic-0.39` which was activated under the genomic conda environment with the following command. 
```
conda activate genomics
```
Then by using the following script, the Illumina adapters were trimmed and a sliding window trimming was done to remove low quality reads from the sequences.
```
#!/bin/bash

FORWARD=$1
REVERSE=$2
ADAPTERS='/home/share/databases/misc/adapters.fa'

mkdir trimmed-reads/

o_for="$(basename $FORWARD)"
o_rev="$(basename $REVERSE)"

trimmomatic PE -threads 32 $FORWARD $REVERSE\
    trimmed-reads/$o_for trimmed-reads/unpaired-$o_for\
    trimmed-reads/$o_rev trimmed-reads/unpaired-$o_rev\
    ILLUMINACLIP:$ADAPTERS:2:30:10:8:true\
    LEADING:3 TRAILING:3\
    SLIDINGWINDOW:4:10 MINLEN:36
```
The produced files include forward paired reads, reverse paired reads, forward unpaired reads, and reverse unpaired reads in the form of `fastq.gz` files. 

# Readmapping
Using the genomics conda environment, the Burrows-Wheeler Alignment tool `bwa-0.7.18`, is used in the following script to align the forward and reverse reads to the reference `fasta file`. The resulting output were `SAM` files.
```
#! /bin/bash

date

FW=$1
RV=$2

name="$(basename "$FW" | cut -d'_' -f1)"

bwa mem -t 24 GCF_023699985.2_Ovbor_1.2_genomic.fna $FW $RV > ./WholeGenomeFiles/$name.sam

echo "DONE"
```
# SAM to BAM
The `SAM` files were then converted into `BAM` files using `samtools-1.20`. This was completed using the following script. The inclusion of the `-F 2308` removed all of the unmapped reads along with the supplementary and secondary alignments to remove any potential false positive or negative results when the varaints were called. This script then moved the resulting `BAM` files to the new directory. 
```
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
```
The `BAM` files were then indexed using `samtools-1.20` and the following script. 
```
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
```
# Variant Calling 
The variants were determined with the reads that had been mapped to the refercence genome. 
This was done by using `bcftools-1.21` in the following script. The resulting output files were `vcf` files. These files were then moved to the directory made in the script. 
```
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
```
# Variant Effect Predictor
The `vcf` files that contained the variants for each individual were then used in the Ensemble Variant Effect Predictor `VEP`. The files first had to be compressed and indexed via `bgzip` and `tabix` as is done with the following script.
```
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
```

# Variant Filtering

# Visualization
![Variant1](https://github.com/user-attachments/assets/9fd74256-d593-4e6e-b512-29549a673699)
![Variant2](https://github.com/user-attachments/assets/4613c8e2-f9c1-4aa8-a129-b1ab00fea978)
![Variant3](https://github.com/user-attachments/assets/33ceebe4-1f0f-45ca-8bb8-ce34bee3ead4)




