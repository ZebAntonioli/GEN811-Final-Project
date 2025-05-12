# GEN811-Final-Project
Final project for bioinformatics lab looking into genetic variant analysis of whitetail deer on Martha's Vineyard

# Background Information
This project is investigating a potential X-linked disorder in *Odocoileus virginianus* or whitetail deer (or white-tailed deer) of Martha's Vineyard. Young male deer, also known as button bucks, have been found showing signs of neurodegeneration. After multiple rounds of negative diagnostic tests, the hypothesis was formed that this could be a genetic disorder and if that was the case, the most likely candidate was that of an X-linked nature since no female deer had been found with the same symptoms. Sequencing was performed on kidney and spleen tissue of five affected and five unaffected deer. These sequences were then used to find potential varaints of interest to explore further. 

# Pipeline Overview
* Obtain Reads
* Trim the reads with Trimmomatic
* Read mapping to the reference genome with Burrows-Wheeler Alignment tool
* Converting the SAM files into BAM files with Samtools
* Variant calling from the BAM files compared to the reference genome with bcftools
* Variant effect predictions from the resulting VCF files using Emsembl Variant Effect Predictor
* Filtering variants that are unique to the affected group compared to the control group
* Visualizing the variants of interest in a JBrowse 2

# Obtaining Reads
Using the `wget` command and the URL provided by the HCGS, the untrimmed `fastq.gz` files were retrieved and imported into my home directory. 
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

# Read Mapping
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
The `SAM` files were then converted into `BAM` files using `samtools-1.20`. This was completed using the following script. The inclusion of the `-F 2308` removed all of the unmapped reads along with the supplementary and secondary alignments to remove any potential false positive or negative results when the variants were called. This script then moved the resulting `BAM` files to the new directory. 
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
The variants were determined with the reads that had been mapped to the reference genome. 
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
Using the following script, `VEP` was used to produce a text output file with the predicted effects the variants in the `vcf` files would have when compared to the reference genome ranging from low to high impact. 
```
#! /bin/bash

date 

directory=$1

source activate ensembl-vep

for x in $(ls $directory)
do
  if [[ $x == *.vcf.gz ]] 
  then
  name="$(basename "$x" .vcf.gz)"
  vep -i $x --fasta GCF_023699985.2_Ovbor_1.2_genomic.fna.gz --gff GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz -o ${name}.txt
  else 
  echo $x is not a zipped vcf
  sleep 5
  fi
done

sleep 5

echo "DONE"
```
# Variant Filtering
The resulting `txt` files were then used to filter out the variants that occurred in both the control and affected group leaving only the unique variants found in the affected group only. This was done by concatenating the affected deer `txt` outputs together as well as the control deer `txt` files into a separate file. These files were then sorted and had all of the repeated lines removed. 
```
cat "affected.txt files" > combined_affected.txt
sort combined_affected.txt | uniq > sorted_combined_affected.txt
cat "control.txt files" > combined_control.txt
sort combined_control.txt | uniq > sorted_combined_control.txt
```
The combined and sorted files were then used with `grep` to remove any variants that occured in the control group as well.
```
grep -Fvx -f sorted_combined_control.txt sorted_combined_affected.txt > unique_affected_variants.txt
```
These unique affected variants were then used to filter out for high impact variants on the X chromosome using `grep`. 
```
grep "069708" unique_affected_variants.txt > unique_affectedXchr_varaints.txt
grep "HIGH" unique_affectedXchr_variants.txt > high_impact_Xchr_varaints.txt
```
To determine if a common high impact variant located on the X chromosome was found across all of the affected deer, the combined `txt` files were used again, but this time, the variants were counted to determine across how many individuals the variant occurred. 
```
sort combined_affected.txt | uniq -c > counted_combined_affected.txt
```
The counted file was then used with `grep` to filter out the unwanted variants by using the unique affected X chromosome variants.
```
grep -F -f unique_affectedXchr_variants.txt counted_combined_affected.txt > counted_uniqueXchr_affected.txt
```
The resulting files are then able to be used to determine which variants unique to the affected deer are of high impact and how many deer were shared the same variant. 
The variant below occurred across four of the five affected deer. 
```
NC_069708.1_51230982_C/T	NC_069708.1:51230982	T	110126703	XM_070461758.1	Transcript	stop_gained	5167	3036	1012	W/*	tgG/tgA	-	IMPACT=HIGH;STRAND=-1;SOURCE=GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz
```
The two variants below occured in three of the five affected deer. 
```
3 NC_069708.1_21635024_CCC/CCCGCCC	NC_069708.1:21635024-21635026	CCCGCCC	110148474	XM_020910489.2	Transcript	frameshift_variant	963-965	963-965	321-322	SP/SPPX	tcCCCa/tcCCCGCCCa	-	IMPACT=HIGH;STRAND=1;SOURCE=GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz

 3 NC_069708.1_1675322_GG/GGG	NC_069708.1:1675322-1675323	GGG	110151672	XM_070461784.1	Transcript	frameshift_variant	1050-1051	1050-1051	350-351	FQ/FPX	ttCCag/ttCCCag	-	IMPACT=HIGH;STRAND=-1;SOURCE=GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz
```
# Visualization
The variants described above were both of high impact as well as in multiple of the affected individuals. The visualization of the variants in relation to the genes that are impacted is important in determining which variants are likely candidates to explore further in determining the root cause of the neurologic disorder of the deer on Martha's Vineyard. `VEP` was used again to produce `vcf` files rather than the `txt` outputs from before with the following script. 
```
#! /bin/bash

date 

directory=$1


for x in $(ls $directory)
do
  if [[ $x == *.vcf.gz ]] 
  then
  name="$(basename "$x" .vcf.gz)"
  vep -i $x --fasta GCF_023699985.2_Ovbor_1.2_genomic.fna.gz --gff GCF_023699985.2_Ovbor_1.2_genomic.sorted.gff.gz --vcf -o ${name}.vcf
  else 
  echo $x is not a vcf
  sleep 5
  fi
done

sleep 5

echo "DONE"
```
The resulting `vcf` files were then used along with the reference `fasta` and `gff` in `JBrowse 2`. This is a genome browsing tool to visualize where the variants are in terms of exons of the genes affected as described in the `txt` and `vcf` files produced by `VEP`. Before loading the `vcf` files into `JBrowse 2`, the files had to be compressed and indexed using the following script. 
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
The resulting files were then able to be downloaded and loaded into `JBrowse 2`. The following figures are of the previously described variants and show the variant along with the location in which the variant occurs within the affected gene. 

The figure below shows the variant that occurs in four of the five affected deer. This variant introduces a transcription stop within the G protein-coupled receptor associated sorting protein 1. The transcription stop occurs in the middle of a reference exon which would most likely negatively affect the protein. The affected protein is associated somewhat with neurologic development, but there was a lack of literature that indicated if a mutation within this protein could lead to neurodegeneration. 
![Variant1](https://github.com/user-attachments/assets/9fd74256-d593-4e6e-b512-29549a673699)

The figure below shows the first of the two varaints that occurs in three of the five affected deer. This varaint introduces a frameshift in the exon of the casein kinase I-like protein. This frameshift could drastically alter the resulting protein hence why the predicted effect of this variant is high. The homologous protein in humans is also associated with neurodegenerative disorders making this variant especially interesting. 
![Variant2](https://github.com/user-attachments/assets/4613c8e2-f9c1-4aa8-a129-b1ab00fea978)

The final variant is the second variant that affects three out of the five deer. This variant is an insertion that causes a frameshift within the exon of the melanoma-associated antigen B17-like protein. The effected gene is not directly tied to neurologic function, but is still an interesting variant. 
![Variant3](https://github.com/user-attachments/assets/33ceebe4-1f0f-45ca-8bb8-ce34bee3ead4) 


# References
Bolger, A. M., Lohse, M., & Usadel, B. (2014). Trimmomatic: a flexible trimmer for Illumina sequence data. Bioinformatics (Oxford, England), 30(15), 2114–2120. https://doi.org/10.1093/bioinformatics/btu170

JBrowse 2: a modular genome browser with views of synteny and structural variation. Genome Biology (2023). https://doi.org/10.1186/s13059-023-02914-z

H. Li, B. Handsaker, A. Wysoker, T. Fennell, J. Ruan, N. Homer, G. Marth, G. Abecasis, R. Durbin, and 1000-Genome-Project-Data-Processing-Subgroup. 2009. The Sequence Alignment/Map format and SAMtools. Bioinformatics. 25(16): 2078-2079.

Li H. (2013) Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. arXiv:1303.3997v1 [q-bio.GN].

H. Li. 2011. A statistical framework for SNP calling, mutation discovery, association mapping and population genetical parameter estimation from sequencing data. Bioinformatics. 27(21): 2987-2993.

McLaren W, Gil L, Hunt SE, Riat HS, Ritchie GR, Thormann A, Flicek P, Cunningham F., P. Danecek, J. K. Bonfield, J. Liddle, J. Marshall, V. Ohan, M. O. Pollard, A. Whitwham, T. Keane, S. A. McCarthy, R. M. Davies, and H. Li. 2021. Twelve years of SAMtools and BCFtools. Gigascience. 10(2): giab008.

The Ensembl Variant Effect Predictor. Genome Biology Jun 6;17(1):122. (2016) doi:10.1186/s13059-016-0974-4
