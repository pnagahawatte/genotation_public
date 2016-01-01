#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

## This script is responsible for parsing records and 
## inserting the records into the genemain and genedetail
## tables
## Each NCBI gene symbol is checked against the genemain table
## If a record for the symbol exists, the record is ignored
## Else, a record is instered into the genemain and genedetail tables

## Command line arguments
my ($help, $ncbi_file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$ncbi_file))
				or defined $help )
{
	print "parse_ncbi.pl [--file ncbi_gene_data_file]\n";
	exit(-1);
}

## Set up the database handle using the
## db connect library
## Refactor by loading the folder to the path
#use lib "../../scripts/SQL/CONN/";
#use db_connect;
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

open( FILE, "< $ncbi_file" ) or die "Can't open $ncbi_file : $!";
while(<FILE>)
{
    if(!(m/^#Format:/))
    {
	my @fields = split "\t", $_;
	## Gather the taxonomy id
	my $taxID = $fields[0];
	## Gather the gene symbol
	my $symbol = $fields[2];
	## Check whether the symbol exists in the genemain table
	#my $cv_event_query = "SELECT EXISTS(SELECT symbol FROM genemain WHERE symbol = $symbol)";
	## REFACTOR: rename the query name as it is not descriptive
	my $cv_event_query = 'SELECT symbol FROM GeneMain WHERE symbol = ? AND taxid = ?';
	my $cv_query_handle = $dbh->prepare($cv_event_query)
		or die "Couldn't prepare statement: " . $dbh->errstr;
	$cv_query_handle->execute($symbol, $taxID);
	
	## Did not find the gene --
	## therefore insert to the database
	if($cv_query_handle->rows == 0)
	{
		## Gather the necessary fields to be inserted
		my $synonyms = $fields[4];
		my $external_ids = $fields[5];
		my $description = $fields[8];
		my $gene_type = $fields[9];
		my $gene_group = "Not provided";
		my $chromosome = $fields[7];
		my $externalID = "Entrez:$fields[2]";
		
		## START -- genemain table
		my $genemain_query = 'insert into GeneMain(symbol, taxID) VALUES(?,?)';
		my $genemain_query_handle = $dbh->prepare($genemain_query);
		$genemain_query_handle->execute($symbol, $taxID);
		##$genemain_$query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## Gather the internal db id, which is the last insert id
		my $db_internal_id = $genemain_query_handle->{mysql_insertid};
		## END -- genemain table
		
		## START -- Genedetail table
		my $genedetail_query = "insert into GeneDetail(	gneomeID, description,
			genetype, genegroup, chromosome) VALUES(?,?,?,?,?)";
		my $genedetail_query_handle = $dbh->prepare($genedetail_query);
		$genedetail_query_handle->execute($db_internal_id, $description,
			$gene_type, $gene_group, $chromosome);
		##$genedetail_$query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## END -- Genedetail table
		
		## START -- synonym table
		$synonyms =~ s/-//g;
		my @synonym_list = split(m/[|]/, $synonyms);
		foreach(@synonym_list)
		{
			my $synonym_query = "insert into GeneSynonym( gneomeID, symbol, taxID) VALUES(?,?,?)";
			my $synonym_query_handle = $dbh->prepare($synonym_query);
			$synonym_query_handle->execute($db_internal_id, $_, $taxID);
			##$synonym_$query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END -- Synonym table	

		## START -- geneexternalid table
		$external_ids =~ s/-//g;
		my @external_id_list = split (m/[|]/, $external_ids);
		foreach(@external_id_list)
		{
			## Split the external id into id and database id
			my @external_db_fields = split ':', $_;
			my $external_id_query = "insert into GeneExternalID( gneomeID, externalID, externalDBID) VALUES(?,?,?)";
			my $external_id_query_handle = $dbh->prepare($external_id_query);
			$external_id_query_handle->execute($db_internal_id, $external_db_fields[1], $external_db_fields[0]);
			##$external_id_$query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END -- geneexternalid table		
	}
    }	#$cv_query_handle->finish();
}
close(FILE);
$dbh->disconnect();
