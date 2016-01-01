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
	print "parse_drug.pl [--file PHARMGKB_drug_file]\n";
	exit(-1);
}

## Set up the database handle using the
## db connect library
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

open( FILE, "< $file" ) or die "Can't open $file : $!";
while(<FILE>)
{
	chomp($_);
	my @fields = split "\t", $_;
	my $accession = $fields[0];
	
	## Parse the fields of the data file and gather to
	## be inserted to the database
	my $drug_names = $fields[1] . "," . $fields[2] . "," . 
		$fields[3] . "," . $fields[4];
	## Add the other fields...

	## Add all the drug names to an array
	my @drug_names;
	## Following are drug names lists.. therefore,
	## add each one of the names
	my @drug_name_fields = split ",", $drug_names;
	foreach (@drug_name_fields)
	{
		my $drugmain_query = 'insert ignore into DrugMain(accessionID, drugname, source) VALUES(?,?,?)';
		my $drugmain_query_handle = $dbh->prepare($drugmain_query);
		$drugmain_query_handle->execute($accession, $_, "PHARMGKB");
		$dbh->commit or die $DBI::errstr;
		## Gather the internal db id, which is the last insert id
		## END -- DRUGMain tabel
	}
}
$dbh->disconnect();