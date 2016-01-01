#!/usr/bin/env perl
use lib "/var/www/Genotation/scripts";
use strict;
use warnings;
use Getopt::Long;

## This script is responsible for parsing records and 
## inserting the records into the pharmgkb_relationships table
## Command line arguments
my ($help, $relationships_file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'relationships_file=s'=>\$relationships_file))
				or defined $help )
{
	print "parse_pharmgkb.pl [--relationships_file pharmgkb_relationships_file]\n";
	exit(-1);
}

use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();
my %drug_records;

open( FILE, "< $relationships_file" ) or die "Can't open $relationships_file : $!";
while(<FILE>)
{
	## Skip first line
    if(!(m/^Entity1_id/))
    {
		my @fields = split "\t", $_;
		my $entity_id = $fields[0];
		my $entity_name = $fields[1];
		$entity_name =~ s/\"//g;
		my $gene_symbol = $fields[4];
		## For efficiency, remove gene symbols that would fail
		if($gene_symbol !~ /^"\S+"$/ && (length $gene_symbol < 11)) 
		{ 
			my $gneome_id_query = "select gneomeID from GeneMain where symbol = ?";		
			my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
			$gneome_id_query_handle->execute($gene_symbol);
			## INSERT A RECORD INTO THE TABLE
			while (my @row = $gneome_id_query_handle->fetchrow_array) {

				$drug_records {"$row[0]:$entity_name:$entity_id"} = '0';
			}
		}
	}
}

my $query = "insert into pharmgkb_relationship (gneomeID, entityName, entityID) VALUES(?,?,?)";
			
for my $key (keys %drug_records)
{
	my $query_handle = $dbh->prepare($query);
	my @fields = split ":", $key;
	$query_handle->execute($fields[0], $fields[1], $fields[2]);
	$query_handle->finish();
	$dbh->commit or die $DBI::errstr;
}
$dbh->disconnect();
