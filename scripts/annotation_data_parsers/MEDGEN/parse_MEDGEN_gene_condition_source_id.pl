#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

## Command line arguments
my ($help, $file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$file))
				or defined $help )
{
	print "parse_MEDGEN_gene_condition_source_id.pl [--file gene_condition_source_id file]\n";
	exit(-1);
}

## Set up the database handle using the
## db connect library
## Refactor by loading the folder to the path
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

open( FILE, "< $file" ) or die "Can't open $file : $!";
while(<FILE>)
{
	## Ignore header line
	if ( !m/^#GeneID/ )
	{
		my @fields = split "\t", $_;
		## The geneIDs belong to NCBI genes. Therefore annotate it accordingly
		my $gene_id = $fields[0];
		my $gene_db_id = "Entrez"; ## This is due to the fact that this NCBI file contains all Entrez IDs
		## Do not want the symbol here to keep data normalized
		#my $symbol = $fields[1];
		my $medgen_id = $fields[2];
		my $disease_name = $fields[3];
		my $source_db = $fields[4];
		my $source_id = $fields[5];
		my $disease_MIM = $fields[6];
		
		## MEDGEN_gene_disease
		my $query = "insert into MEDGEN_gene_disease(externalID, externalDBID, medgenID, diseaseName, sourceDB, sourceID, diseaseMIM) VALUES(?,?,?,?,?,?,?)";
		my $query_handle = $dbh->prepare($query);
		$query_handle->execute($gene_id, $gene_db_id, $medgen_id, $disease_name, $source_db, $source_id, $disease_MIM);
		$query_handle->finish();
		$dbh->commit or die $DBI::errstr;
	}
}
$dbh->disconnect();
