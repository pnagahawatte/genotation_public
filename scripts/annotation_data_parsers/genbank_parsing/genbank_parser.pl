#!/usr/bin/env perl

use strict;
use warnings;

## Variables that belong to a section, and will change line by line
my $gene_name = "Gene_symbol";
my $accession = "Accession";
my $journal = "Journal";
my $pubmedID = "Pubmed_id,";
my $gene_summary = "Gene_summary";
my $dbsnp = "dbSNP";

## Partition between sections to gather specific fields
my $is_gene_summary = "false";
my $is_COMMENT = "false";
my $is_FEATURE = "false";
my $is_variation = "false";

while(<STDIN>)
{
	## LOCUS tag: This will specify when to flush teh buffer and
	## and write a line which contains all the details
	if (m/^LOCUS/)
	{
		## Remove the last comma from the pubmed ID list
		$pubmedID = substr  $pubmedID, 0, -1;
		$dbsnp = substr  $dbsnp, 0, -1;
		## Print None if there are not any pubmed IDs
		if($pubmedID eq "") { $pubmedID = "None";}		
		if($gene_summary eq "") { $gene_summary = "None"; }
		if($dbsnp eq "") {$dbsnp = "None";}
		if($accession eq "") {$accession = "None";}
		if($gene_name eq "") {$gene_name = "None";}
		print "$gene_name\t$accession\t$gene_summary\t$pubmedID\t$dbsnp\n";
		$gene_name = "";
		$accession = "";
		$pubmedID  = "";
		$gene_summary = "";
		$dbsnp = "";
	}
	
	## DEFINITION tag: 
	if (m/^DEFINITION/)
	{
		my $definition_line = $_;
		($gene_name) = $definition_line =~ m/\((.+)\)/;
	}
	
	## ACCESSION tag: 
	if (m/^ACCESSION/)
	{
		my $accession_line = $_;
		($accession) = $accession_line =~ m/(NM_.+)/;
	}
	
	## PUBMED tag: These will be concatenated, delimited by a comma
	if (m/PUBMED/)
	{
		my $pubmed_line = $_;
		my ($pubmed) = $pubmed_line =~ m/([0-9]+)/;
		$pubmedID .= $pubmed . ",";
	}
	
	## COMMENT tag: This will just turn on the is_comment flag
	if(m/COMMENT/)
	{
		$is_COMMENT = "true";
	}
	
	## Gather the gene summare information between the COMMENT and FEATURES tags
	if($is_COMMENT && (m/Summary:/))
	{
		$is_gene_summary = "true";
	}
	
	## Set the is_gene_summary to false if the gene summary section is completed
	if (($is_gene_summary eq "true" && $_ =~ /^$/) ||
		($is_gene_summary eq "true" && $_ =~ /Transcript Variant:/) ||
		($is_gene_summary eq "true" && $_ =~ /FEATURES/) ||
		($is_gene_summary eq "true" && $_ =~ /COMPLETENESS:/))
	{
		$is_gene_summary = "false";
	}
	if($is_gene_summary eq "true")
	{
		chomp($_);
		$_ =~ s/^\s+|\s+$//;
		$gene_summary .= " $_";
		$gene_summary =~ s/^\s*Summary://;
	}

	## FEATURES tag: This will turn off the is_COMMENT flag
	if(m/FEATURES/)
	{
		$is_COMMENT = "false";
		$is_gene_summary = "false";
		$is_FEATURE = "true";
	}
	
	if($is_FEATURE && (m/^\s*variation/))
	{
		$is_variation = "true";
	}
	
	if(m/ORIGIN/)
	{
		$is_variation = "false";
	}
	
	if($is_variation eq "true")
	{
		if(m/^\s*\/db_xref=/)
		{
			chomp($_);
			$_ =~ s/^\s+|\s+$//;
			$_ =~ s/^\s*\/db_xref=//;
			$_ =~ s/"//g;
			$dbsnp .= $_ . ",";
		}
	}
	
	
}

## Flush out the last line, since there will not be another LOCUS line
## Remove the last comma from list
$pubmedID = substr  $pubmedID, 0, -1;
$dbsnp = substr  $dbsnp, 0, -1;
## Print None if there are not any pubmed IDs
if($pubmedID eq "") { $pubmedID = "None";}
if($gene_summary eq "") { $gene_summary = "None"; }		
if($dbsnp eq "") {$dbsnp = "None";}
print "$gene_name\t$accession\t$gene_summary\t$pubmedID\t$dbsnp\n";