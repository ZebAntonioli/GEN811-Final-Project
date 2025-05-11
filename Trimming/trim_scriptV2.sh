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
