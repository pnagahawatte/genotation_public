#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
#
## Command line arguments
my ($help, $file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$file))
				or defined $help )
{
	print "parse_uniprotkb.pl [--file uniprot-kb file]\n";
	exit(-1);
}

## Set up the database handle using the
## db connect library
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

open( FILE, "< $file" ) or die "Can't open $file : $!";
while(<FILE>)
{

## Sample lines:
## Entry	Entry name	Status	Protein names	Gene names	Organism	Length
## P31946	1433B_HUMAN	reviewed	14-3-3 protein beta/alpha (Protein 1054) (Protein kinase C inhibitor protein 1) (KCIP-1) [Cleaved into: 14-3-3 protein beta/alpha, N-terminally processed]	YWHAB	Homo sapiens (Human)	246

	## Ignore the header line
	if(!(m/^Entry/))
    {
		## Split all the fields by tab
		my @fields = split "\t", $_;
		## Gather the fields into variables
		my $uniprot_entry = $fields[0];
		if($fields[2] eq "reviewed")
		{
			my @name_fields = "no";
			## Special consideration for "[0-9]," "Actin," "cDNA," "Alpha-1,"
			#if ($fields[3] =~ /^3'\(2'\),5'/ ) {print "here"}; #{ @name_fields = split /^3'(2'),5'[\s\S]*\b\(/, $fields[3];}
			if ($fields[3] =~ /^(5'\(|3'\(2'\),5'|Alpha-\(|Alpha\(1)|Anti-\(|Ataxin-\(|O\(/ )  { @name_fields = split ' \(', $fields[3];}
			elsif ($fields[3] =~ /^(Actin,|Alpha-1,|cDNA,|[0-9],|2',|3',|5',|)/ ) { @name_fields = split /\(/, $fields[3];}
			elsif ($fields[3] =~ /^DNA \(/) {@name_fields = $fields[3]; }
			elsif ($fields[3] =~ /^DNA \(/) {@name_fields = split ",", $fields[3]; }
			else { @name_fields = split /[\(|,]/, $fields[3]; }
			## Assign the term
			my $uniprot_description = "$name_fields[0]";
			## Only proceed if a gene symbol is mentioned...
			if ($fields[4] !~ /^\s*$/ ) {
				my @gene_symbols = split " ", $fields[4];
				my $symbol = $gene_symbols[0];
				
				## Gather the genomeID
				my $query = "insert ignore into uniprot (uniprot_entry, gneomeID, uniprot_description) VALUES(?,?,?)";
				my $gneome_id_query = "select gneomeID from GeneMain where symbol = ?";		
				my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
				$gneome_id_query_handle->execute($symbol);
				
				## INSERT A RECORD INTO THE TABLE
				while (my @row = $gneome_id_query_handle->fetchrow_array) {
					my $query_handle = $dbh->prepare($query);
					$query_handle->execute($uniprot_entry, $row[0], $uniprot_description);
					$query_handle->finish();
					$dbh->commit or die $DBI::errstr;
				}
			}
		}
	}
}

