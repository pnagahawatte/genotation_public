#!/usr/bin/bash

## This script extracts the necessary fields from the HUGO hgnc file
## to be loaded in to the main_gene table

## Usage information
if test $# -lt 3; then
	echo "Usage: hgnc_to_table_format.sh <hgnc file> <tax_id> <data for table>"
	echo "Choices for data for table: gene_main | gene_detail | synonym | history"
	exit -1;
fi

hgnc_file=$1
tax_id=$2
table_name=$3

## process the file
## There might be records with status, if so, ignore them
## To do this create a temporary file with only approved records

## Do not use the header as it has spaces, and will create issues later in the script
##head -n 1 $hgnc_file > Approved_only_hgnc_file.txt
grep "Approved" $hgnc_file > Approved_only_hgnc_file.txt

## Create the data to be loaded into the main_gene table
if [ $table_name == "gene_main" ]; then
	awk -v t_id=$tax_id '{printf("%s\t%s\n",$2,t_id)}' Approved_only_hgnc_file.txt
fi

## Create the data to be loaded into the synonym table
if [ $table_name == "synonym" ]; then
	while read id gene_symbol aa bb cc dd ee ff synonyms gg
	do
		if [[ $synonyms =~ ^[A-Z] ]]; then
		## Replace the previously introduced place holders for spaces: "_"
		spaces_removed=`echo ${synonyms//_/}`
		#echo "$gene_symbol	$spaces_removed"

			## Convert the comma separated list of synonyms to an array, and
			## print one line for each synonym
			OIFS=$IFS
			IFS=","
			symbol_array=($spaces_removed)
			## Print one line for each synonym
			for element in "${symbol_array[@]}"
			do
				echo "$gene_symbol	$element"
			done
			IFS=$OIFS;
fi
	done<Approved_only_hgnc_file.txt
fi

## Create the data to be loaded into the history table
if [ $table_name == "history" ]; then
	while read line
	do
		gene_symbol=`echo $line | cut -f 2 -d " "`
		historical_names=`echo $line | cut -f 7 -d " "`
		if [ -n "$synonyms" ]; then
			## Remove all the spaces after the commas to make it easier for the loader
			names_no_spaces=`echo $historical_names | tr -d " "`
			## Convert the comma separated list of synonyms to an array, and
			## print one line for each synonym
			OIFS=$IFS
			IFS=","
			symbol_array=(${names_no_spaces//,/ })
echo $symbol_array[0]
			IFS=$OIFS;
		fi
	done<Approved_only_hgnc_file.txt
fi

## Create the data to be laoded into the gene_detail table
if [ $table_name == "gene_detail" ]; then
		#while read id aa name bb locus_type locus_group ee ff gg hh chromosome ii
	cut -f 1,2,3,5,6,11 Approved_only_hgnc_file.txt
fi


## Clean up files..
rm Approved_only_hgnc_file.txt	
