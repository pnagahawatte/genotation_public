#!/usr/bin/env perl

use strict;
use warnings;
use SQL::CONN::db_connect;
use Getopt::Long;

## Command line arguments
my ($help, $folder, %gene_mapping, @pathway_genes, %gneome_gene_list, 
	%pathway_names, %pathway_origin, %pathway_pairs, %pathway_rs);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'folder=s'=>\$folder)) or defined $help )
{
	print "find_gene_words.pl <--folder absolute path to the data folder>\n";
	exit(-1);
}

## Setup the database connection
my $dbh = SQL::CONN::db_connect->get_connection();

## The Pathway API downloaded from http://www.pathwayapi.com/
## contains the following files, which will be used:
## gene_mapping.csv  pathway_genes.csv  pathway_names.csv  
## pathway_origin.csv  pathway_pairs.csv  pathway_rs.csv
## Read in all the files from the folder and generate 
## corresponding hashes
## START -- gene_mapping.csv
open( FILE, "< $folder\/gene_mapping.csv" ) or die "Can't open the text file : $!";
while(<FILE>) 
{
	## The records are in the following format:
	## "gene_id";"gene_name"
	$_ =~ s/\s*//g;
	my @fields = split ";", $_;
	$fields[1] =~ s/"//g;
	chomp($fields[1]);
	$fields[0] =~ s/"//g;
	chomp($fields[0]);
	$gene_mapping{$fields[0]} = $fields[1];
}
close (FILE);
## END - gene_mapping.csv

## START - pathway_origin
open( FILE, "< $folder\/pathway_origin.csv" ) or die "Can't open the text file : $!";
while(<FILE>) 
{
	## The records are in the following format:
	## "origin";"origin_name"
	$_ =~ s/\s*//g;
	my @fields = split ";", $_;
	$fields[1] =~ s/"//g;
	chomp($fields[1]);
	$fields[0] =~ s/"//g;
	chomp($fields[0]);
	$pathway_origin{$fields[0]} = $fields[1];
}
close (FILE);
## END - pathway_orgin

## START - pathway_names
open( FILE, "< $folder\/pathway_names.csv" ) or die "Can't open the text file : $!";
while(<FILE>) 
{
	## The records are in the following format:
	## "pathway_id";"pathway_name";"pathway_oid";"origin"
	$_ =~ s/\s*//g;
	my @fields = split ";", $_;
	$fields[0] =~ s/"//g;
	$fields[1] =~ s/"//g;
	$fields[2] =~ s/"//g;
	$fields[2] =~ s/path://;
	$fields[3] =~ s/"//g;
	$pathway_names{$fields[0]} = "$fields[1];$fields[2];$pathway_origin{$fields[3]}";
#print "$fields[1];$fields[2];$pathway_origin{$fields[3]}\n";
}
close (FILE);
## END - pathway_names

## START - pathway_genes
open( FILE, "< $folder\/pathway_genes.csv" ) or die "Can't open the text file : $!";
while(<FILE>) 
{
	## The records are in the following format:
	## "pathway_id";"gene_id";"origin"
	$_ =~ s/\s*//g;
	my @fields = split ";", $_;
	$fields[0] =~ s/"//g; ## pathway_id
	$fields[1] =~ s/"//g; ## gene_id
	$fields[2] =~ s/"//g; ## origin
	if ( $fields[1] =~ /^([0-9]*)$/ ) 
	{
		my @pathway_fields = split ";", $pathway_names{$fields[0]};
		my $pathway_description = $pathway_fields[0];
		my $pathway_oid = $pathway_fields[1];
		push @pathway_genes, "$pathway_oid;$gene_mapping{$fields[1]};$pathway_origin{$fields[2]};$pathway_description"; 
#print "$pathway_oid;$gene_mapping{$fields[1]};$pathway_origin{$fields[2]};$pathway_description\n";
	}
}
close (FILE);
## END - pathway_genes
## START - pathway_rs
open( FILE, "< $folder\/pathway_rs.csv" ) or die "Can't open the text file : $!";
while(<FILE>) 
{
	## The records are in the following format:
	## "pathway_id";"gene_id1";"gene_id2";"rs"
	$_ =~ s/\s*//g;
	my @fields = split ";", $_;
	$fields[0] =~ s/"//g;
	$fields[1] =~ s/"//g;
	$fields[2] =~ s/"//g;
	$fields[2] =~ s/path://;
	#$fields[3] =~ s/"//g;
	#$pathway_rs{$fields[0]} = "$fields[1];$fields[2];$pathway_origin{$fields[3]}";
	#print "$fields[1];$fields[2];$pathway_origin{$fields[3]}\n";
}
close (FILE);
## END - pathway_rs
#END - gathering data from the files

## Gather gene symbol data from the database
## Prepare the gene_list hash with all the gene symbol from the database
## Only the taxid 9606 ( human) is selected here
my $gneome_id_query = "select symbol, gneomeID from genemain where taxid=?";
my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
$gneome_id_query_handle->execute("9606");
while (my @row = $gneome_id_query_handle->fetchrow_array) {
	## gene_list{gneomeID} = symbol;
	$gneome_gene_list{$row[0]} = $row[1];
}

## Compile the data for the tables
## Start pathway_genes table
## Columns: pathway_origin_id	gneome_id	origin_name
foreach (@pathway_genes)
{
	my @fields = split ";", $_;
	my $pathway_id = $fields[0];
	my $gene_symbol = $fields[1];
	my $gneome_id = $gneome_gene_list{$gene_symbol};
	my $origin = $fields[2];
	my $pathway_description = $fields[3];
	if($pathway_id ne "" && $gneome_id ne "" && $origin ne "")
	{
		my $annotation_pathway_query = "INSERT INTO annotation_pathways (PathwayID, PathwayDescription, GneomeID, Origin) VALUES(?,?,?, ?)";
		my $annotation_pathway_query_handle = $dbh->prepare($annotation_pathway_query);
		$annotation_pathway_query_handle->execute($pathway_id, $pathway_description, $gneome_id, $origin);
		$dbh->commit or die $DBI::errstr;
	}
}

## Close the db connection
$dbh->disconnect();