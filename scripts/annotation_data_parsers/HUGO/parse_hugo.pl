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
	print "parsehugo.pl [--file HUGO_gene_file]\n";
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
	if ( m/HGNC:/ && !(m/~withdrawn/))
	{
		chomp($_);
		my @fields = split "\t", $_;
		$fields[0] =~ s/^HGNC://;
		my $external_db_id = $fields[0];
		
		## Parse the fields of the data file and gather to
		## be inserted to the database
		my $tax_id = "9606";
		my $symbol = $fields[1];
		my $description = $fields[2];
		my $gene_type = $fields[4];
		my $gene_group = $fields[5];
		my $synonyms = $fields[8];
		my $chromosome = $fields[10];
		my $enzyme_id = $fields[16];
		
		## External db ids are shown in 2 columns, pick the
		## populated column giving preference to the HUGO column
		## entrez
		my $entrez_id = "";
		if ($fields[17] ne "") { $entrez_id = $fields[17]; }
		else { my $entrez_id = $fields[32]; }
		
		## Ensembl
		my $ensembl_id = "";
		if ($fields[18] ne "") { $ensembl_id = $fields[18]; }
		else { my $ensembl_id = $fields[36]; }
		
		## Mouse
		my $mouse_id = "";
		if ($fields[19] ne "") { $mouse_id = $fields[19]; }
		else { my $entrez_id = $fields[38]; }
		
		my $pubmed_ids = $fields[22];
		
		## Refseq
		my $refseq_id = "";
		if ($fields[23] ne "") { $refseq_id = $fields[23]; }
		else { my $refseq_id = $fields[34]; }
		
		my $gene_family = $fields[24];
		my $gene_family_description = $fields[25];
		my $vega_id = $fields[30];
		my $omim_id = $fields[33];
		my $uniprot_id = $fields[35];
		my $ucsc_id = $fields[37];
		my $rat_id = $fields[39];	
		
		## Create an array for all the external IDs
		my @external_id_list;
		## Add to the external ID list, if that field is not empty
		## Add a HGNC record with the current gene ID
		## This is added to the GeneExternalDB table, for later reference
		if ($external_db_id ne "") { push @external_id_list, "HGNC:$external_db_id"; }
		if ($entrez_id ne "") {push @external_id_list, "Entrez:$entrez_id"; }
		if ($ensembl_id ne "") { push @external_id_list, "Ensembl:$ensembl_id"; }
		if ($refseq_id ne "") { push @external_id_list, "Refseq:$refseq_id"; }
		if ($vega_id ne "") { push @external_id_list, "Vega:$vega_id"; }
		if ($uniprot_id ne "") { push @external_id_list, "Uniprot:$uniprot_id"; }
		if ($ucsc_id ne "") { push @external_id_list, "UCSC:$ucsc_id"; }
		if ($mouse_id ne "") { push @external_id_list, "$mouse_id"; }
		if ($rat_id ne "") { push @external_id_list, "$rat_id"; }
		
		## START -- geneMain table
		my $genemain_query = 'insert into GeneMain(symbol, taxID) VALUES(?,?)';
		my $genemain_query_handle = $dbh->prepare($genemain_query);
		$genemain_query_handle->execute($symbol, $tax_id);
		##$genemain_$query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## Gather the internal db id, which is the last insert id
		my $db_internal_id = $genemain_query_handle->{mysql_insertid};
		## END -- geneMain tabel
		
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
		my @synonym_list = split(m/[,]/, $synonyms);
		foreach(@synonym_list)
		{
			$_ =~ s/^\s+|\s+$|^_//g;
			my $synonym_query = "insert into GeneSynonym( gneomeID, symbol, taxID) VALUES(?,?,?)";
			my $synonym_query_handle = $dbh->prepare($synonym_query);
			$synonym_query_handle->execute($db_internal_id, $_, $tax_id);
			##$synonym_$query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END -- Synonym table
		
		## START -- geneexternalid table
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
}
$dbh->disconnect();
