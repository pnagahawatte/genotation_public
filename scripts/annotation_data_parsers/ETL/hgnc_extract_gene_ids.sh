#!/usr/bin/bash

## This script takes the spaces removed HGNC data file
## For each gene symbol, it will extract the corresponding 
## external gene ids that belong to different databases such
## as HUGO, NCBI OMIM etc.
## The script also looks up the internal id, and prints out a 
## line for each of the ids in the following format:
## internal_id	external_db_id	external_db_description

## Usage information
if test $# -lt 1; then
	echo "Usage: hgnc_to_table_format.sh <hgnc file>"
	exit -1;
fi

hgnc_file=$1

## Create the 
