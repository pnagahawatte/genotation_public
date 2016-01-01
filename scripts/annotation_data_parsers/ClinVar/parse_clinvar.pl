#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use List::MoreUtils qw(uniq);

## Set up the database handle using the
## db connect library
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

use LWP::UserAgent;

## Remove the existing tables

#if ($#ARGV < 0)
#{
#	print "Usage: parse_clinvar.pl <clinvar_data_file> \n";
#	exit;
#}

## Command line arguments
my ($help, $clinvar_file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$clinvar_file))
				or defined $help )
{
	print "parse_clinvar.pl [--file clinvar_data_file]\n";
	exit(-1);
}

open( FILE, "< $clinvar_file" ) or die "Can't open $clinvar_file : $!";

my $line = 0;
my $db_internal_id;

while(<FILE>)
{
	## Refactor: There is a bug here, which does not affect teh initial phase
	## because we are not concerned about variant level detail, but about gene level detail
	## For future use, compensate for multiple variants that are denoted by a comma in field #5
	## This is reflected in the INFO fields as well
	
	## Fields to be inserted into the database
	## Table CV_variant
	my $chrom;
	my $rspos;
	my $rsid;	
	
	my $info;
	
	## Table CV_external_db
	my (@dbs, @dbids, @uniq_dbs, @uniq_dbids);
	
	my $reference_allele;
	my $alternative_allele;

	## Table CV_event_details
	my ($NSF, $NSM, $NSN) = (0,0,0);
	my ($COMMON, $PM) = (0,0);
	my ($CLNSIG, $CLNORIGIN) = (-1, -1);
	my $VC = "NA";

	## CV_event_gene table
	my ($gene_symbol, $gene_entrez_id);
	
	## Ignore the comment lines
	if ($_ !~ '^#')
	{
		$line++;
		chomp($_);
		my @fields = split "\t", $_;
		$chrom = $fields[0];
		$rspos = $fields[1];
		$rsid = $fields[2];
		$reference_allele = $fields[3];
		$alternative_allele = $fields[4];
#		$quality = $fields[5];
#		$filter = $fields[6];
		$info = $fields[7];		
		
		## CV_variant
		## Create the CV_variant record for the rsID, chrom and rspos
		## This will be the master record for the clinvar events
		## The internal db id will be used in the foreign keys for the other
		## tables in the db
		my $query = "insert into CV_variant (rsID, chrom, rspos) VALUES(?,?,?)";
		my $query_handle = $dbh->prepare($query);
		$query_handle->execute($rsid, $chrom, $rspos);
		$query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## Gather the internal db id, which is the last insert id
		$db_internal_id = $query_handle->{mysql_insertid};

		my (@clndsdb, @clndsdbid); ## To be used to store the dbs and dbids
		
		chomp($info);
		my @info_fields = split ";", $info;
		undef @dbs;
		undef @uniq_dbs;
		undef @dbids;
		undef @uniq_dbids;
		
		foreach(@info_fields)
		{
			## "Variant disease database name"
			## CLNDSDB
			if ($_ =~ '^CLNDSDB')
			{ 
				## Split the field
				my @split_fields = split "=", $_;
				
				## Is it a database entry or a database ID entry?
				if ( $split_fields[0] eq "CLNDSDB" )
				{
					 @dbs = split(m/[:|,]/, $split_fields[1]);
					 ## BUG: the uniq might not be working correctly - check
					 @uniq_dbs = uniq(@dbs);
					 #foreach (@dbs) {print $_ . "\n"; }
				}
				else
				{
					@dbids = split(m/[:|,]/, $split_fields[1]);
					## BUG: the uniq might not be working correctly - check
					@uniq_dbids = uniq(@dbids);
					#foreach (@dbids) {print $_ . "\n"; }
				}				
			}
			
			## "Pairs each of gene symbol:gene id.  The gene symbol and id are delimited by a 
			## colon (:) and each pair is delimited by a vertical bar (|)"
			## GENEINFO
			## -- START CV_event_gene
			if ($_ =~ '^GENEINFO')
			{ 
				## Insert the records into CV_event_gene table
				my @fields = split "=", $_;
				$fields[1] =~ s/:/\t/g;
				my @multi_field = split '\|', $fields[1];
				## To compensate for peculiarities 
				my @uniq_multi_field = uniq(@multi_field);
				foreach(@uniq_multi_field)
				{
					my @gene_fields = split "\t", $_;
					#print "$line\t$gene_fields[0]\t$gene_fields[1]\n";
					my $symbol = $gene_fields[0];
					my $entrez_id = $gene_fields[1];
					my $query = "insert into CV_event_gene (gneomeCVID, gneomeID, externalid, externaldbid) VALUES(?,?,?,?)";
			my $gneome_id_query = "select gneomeID from GeneMain where symbol = ?";		
			my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
			$gneome_id_query_handle->execute($symbol);
			## INSERT A RECORD INTO THE TABLE
			while (my @row = $gneome_id_query_handle->fetchrow_array) {
				
				
				my $query_handle = $dbh->prepare($query);
				$query_handle->execute($db_internal_id, $row[0], $entrez_id, "Entrez");
				$query_handle->finish();
				$dbh->commit or die $DBI::errstr;
				
				
			}
					
					
					
					
					## Gather the internal db id, which is the last insert id
				}
			}
			## -- END CV_event_gene
			
			## START -- CV_event_details
			## "Allele Origin. One or more of the following values may be added: 0 - unknown; 
			## 1 - germline; 2 - somatic; 4 - inherited; 8 - paternal; 16 - maternal; 32 - de-novo; 
			## 64 - biparental; 128 - uniparental; 256 - not-tested; 512 - tested-inconclusive; 1073741824 - other"
			#CLNORIGIN
			if ($_ =~ '^CLNORIGIN') 
			{
				## Some CLNSIG have multiple values delimited by | and ,
				$_ =~ s/CLNORIGIN=//;
				$_ =~ s/[|,]/\t/g;
				my @fields = split "\t", $_;
				## BUG ALERT: We are only using the first clnsig value here
				## it is because we are only using the first event 
				$CLNORIGIN = $fields[0];	
			}
			## "Variant Clinical Significance, 0 - Uncertain significance, 1 - not provided, 2 - Benign, 
			## 3 - Likely benign, 4 - Likely pathogenic, 5 - Pathogenic, 6 - drug response, 7 - histocompatibility, 255 - other"
			#CLNSIG
			if ($_ =~ '^CLNSIG')
			{
				## Some CLNSIG have multiple values delimited by | and ,
				$_ =~ s/CLNSIG=//;
				$_ =~ s/[|,]/\t/g;
				my @fields = split "\t", $_;
				## BUG ALERT: We are only using the first clnsig value here
				## it is because we are only using the first event 
				$CLNSIG = $fields[0];
			}
			##"Has non-synonymous frameshift A coding region variation where one allele in the set changes all downstream amino acids."
			## NSF
			if ($_ =~ '^NSF') { $NSF = 1; }
			##"Has non-synonymous missense A coding region variation where one allele in the set changes protein peptide."
			## NSM
			if ($_ =~ '^NSM') { $NSM = 1; }
			## "Has non-synonymous nonsense A coding region variation where one allele in the set changes to STOP codon (TER)"
			## NSN
			if ($_ =~ '^NSN') { $NSN = 1; }
			## "RS is a common SNP.  A common SNP is one that has at least one 1000Genomes
			## population with a minor allele of frequency >= 1% and for which 2 or more 
			## founders contribute to that minor allele frequency."
			#COMMON
			if ($_ =~ '^COMMON=1') { $COMMON = 1; }
			## "Variant is Precious(Clinical,Pubmed Cited)"
			## PM
			if ($_ =~ '^\bPM\b') { $PM = 1; }
			## END -- CV_event_details
			## "Variation Class"
			## VC
			if ($_ =~ '^\bVC\b') 
			{
				$_ =~ s/VC=//;
				$VC = $_;
			}
		}
		## START -- CV_external_db 
		## Insert the details of the external disease databases per line
		for my $i(0 .. $#uniq_dbs-1)
		{
			## "Variant disease database ID"
			## CLNDSDBID		
			my $query = "insert into CV_external_db (gneomeCVID, externalid, externaldbid) VALUES(?,?,?)";
			my $query_handle = $dbh->prepare($query);
			$query_handle->execute($db_internal_id,$uniq_dbids[$i],$uniq_dbs[$i]);
			$query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END -- CV_external_db 
		
		## CV_event_details
		## Insert individual event details into the CV_event_details table
		my $cv_event_query = "insert into CV_event_details (gneomeCVID, clnsig, clnorigin, nsf, nsm, nsn, vc, common, pm) VALUES(?,?,?,?,?,?,?,?,?)";
		my $cv_query_handle = $dbh->prepare($cv_event_query);
		$cv_query_handle->execute($db_internal_id, $CLNSIG,
			$CLNORIGIN, $NSF, $NSM, $NSN, $VC, $COMMON, $PM);
		$cv_query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## END -- CV_event_details
	}
}
close(FILE);
$dbh->disconnect();
