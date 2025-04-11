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

# Obtaining Reads
Using the 'wget' command and the URL provided by the HCGS, the untrimmed 'fastq.gz' files were retrieived and imported into my home directory. 
```
wget "example_url"
```

# Trimming
Trimming was done with the use of 'Trimmomatic'. The genomics conda environment must first be activated.
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
The produced files include forward paired reads, reverse paired reads, forward unpaired reads, and reverse unpaired reads in the form of 'fastq.gz' files. 

# Readmapping
Using the genomics conda environment, the Burrows-Wheeler Alignment tool, or 'bwa', is used in the following script to align the forward and reverse reads to the reference 'fasta file'.
```
#! /bin/bash

date

FW=$1
RV=$2

name="$(basename "$FW" | cut -d'_' -f1)"

bwa mem -t 24 GCF_023699985.2_Ovbor_1.2_genomic.fna $FW $RV > ./WholeGenomeFiles/$name.sam

echo "DONE"
```
