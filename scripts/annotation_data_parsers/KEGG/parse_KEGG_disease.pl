#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

## Set up the database handle using the
## db connect library
use SQL::CONN::db_connect;
my $dbh = SQL::CONN::db_connect->get_connection();

## Command line arguments
my ($help, $kegg_disease_file);
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$kegg_disease_file))
				or defined $help )
{
	print "parse_KEGG_disease.pl [--file kegg_disease_file]\n";
	exit(-1);
}

open( FILE, "< $kegg_disease_file" ) or die "Can't open $kegg_disease_file : $!";

my $line = 0;
my $db_internal_id;
my ($in_name, $in_gene, $in_drug, $in_marker, $in_pathway, $in_comment, $in_env_factor) = (0,0,0,0,0,0,0);
my ($kegg_disease_id, $name, $description, $category, $comment, $env_factor);
my ($pathway, $pathway_description);
my (@gene, @drug, @marker, @reference, @pathway, @comment, @env_factor);
my $test = 1;	
while(<FILE>)
{
$line++;
	## Work on one record
	## Insert the previous record to the database
	## when a record switches to the next
	if ( $_ =~ '^///' ) 
	{
		## Switching to the next record

		## START: KEGGdisease table
		my $kegg_disease_query = "insert into KEGGdisease (keggDiseaseID, 
			name, description, category, envFactor, comment) VALUES(?,?,?,?,?,?)";
		my $kegg_disease_query_handle = $dbh->prepare($kegg_disease_query);
		$kegg_disease_query_handle->execute($kegg_disease_id, $name, $description, $category, $env_factor, $comment);
		$kegg_disease_query_handle->finish();
		$dbh->commit or die $DBI::errstr;
		## END: KEGGdisease
		
		## START: KEGGdrug table
		my $kegg_drug_query = "insert into KEGGdrug (keggDiseaseID, drug, description) VALUES(?,?,?)";
		my $kegg_drug_query_handle = $dbh->prepare($kegg_drug_query);
		foreach(@drug)
		{
			my @fields = split ",", $_;
			$kegg_drug_query_handle->execute($kegg_disease_id, $fields[0], $fields[1]);
			$kegg_drug_query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END: KEGGdrug table

		## START: KEGGgene table
		my $kegg_gene_query = "insert into KEGGgene (keggDiseaseID, gneomeID, keggGeneID, keggOrthologyID) VALUES(?,?,?,?)";
		my $gneome_id_query = "select gneomeID from GeneMain where symbol = ?";

		foreach(@gene)
		{
			my @fields = split ",", $_;
			my $symbol = $fields[0];
			my $kegg_orthology_id = $fields[1];
			my $kegg_gene_id = $fields[2];
			
			## Gather the gneomeid, as we need that to insert to the table
			my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
			$gneome_id_query_handle->execute($symbol);
			## INSERT A RECORD INTO THE TABLE
			while (my @row = $gneome_id_query_handle->fetchrow_array) {
				my $kegg_gene_query_handle = $dbh->prepare($kegg_gene_query);
				$kegg_gene_query_handle->execute($kegg_disease_id, $row[0], $kegg_gene_id, $kegg_orthology_id);
				$kegg_gene_query_handle->finish();
				$dbh->commit or die $DBI::errstr;
			}
			## REFACTOR: WHAT IF GNEOMEID COULD NOT BE FOUND???
		}
		## END: KEGGgene table
		
		## START: KEGGpathway table
		my $kegg_pathway_query = "insert into KEGGpathway (keggDiseaseID, pathway, description) VALUES(?,?,?)";
		foreach(@pathway)
		{
			my @fields = split ",", $_;
			my $kegg_pathway_query_handle = $dbh->prepare($kegg_pathway_query);
			$kegg_pathway_query_handle->execute($kegg_disease_id, $fields[0], $fields[1]);
			$kegg_pathway_query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END: KEGGpathway table

		## REFACTOR: SPLIT THIS INTO THE MARKER AND MARKER GENE TABLES
		## START: KEGGmarker table
		my $kegg_marker_query = "insert into KEGGmarker (keggDiseaseID, description) VALUES(?,?)";
		foreach(@marker)
		{
			my $kegg_marker_query_handle = $dbh->prepare($kegg_marker_query);
			$kegg_marker_query_handle->execute($kegg_disease_id, $_);
			$kegg_marker_query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END: KEGGmarker table
		
		## START: KEGGreference table
		my $kegg_reference_query = "insert into KEGGreference (keggDiseaseID, pubmedid, description) VALUES(?,?,?)";
		foreach(@reference)
		{
			my @fields = split ",", $_;
			my $kegg_reference_query_handle = $dbh->prepare($kegg_reference_query);
			## The description could be missing in some of the records
			## Handle them appropriately

			if ($fields[0] ne "" and defined $fields[1]) 
			{
				$kegg_reference_query_handle->execute($kegg_disease_id, $fields[0], $fields[1]);
			}
			elsif ($fields[0] ne "" and ! defined $fields[1])
			{
				$kegg_reference_query_handle->execute($kegg_disease_id, $fields[0], "");
			}
			elsif ($fields[0] eq "") {}
			$kegg_reference_query_handle->finish();
			$dbh->commit or die $DBI::errstr;
		}
		## END: KEGGreference table
		
		## Clear the arrays
		undef @gene;
		undef @drug; 
		undef @marker;
		undef @reference;
		undef @pathway;
		undef $comment;
		undef $env_factor;
		undef $kegg_disease_id;
	}
	
	## Gather all the records until the record switch
	## characters are encountered
	else
	{
		chomp($_);
		
		## Parse each line -- identified by the tag
		## Find the kegg id
		if ( $_ =~ '^ENTRY') 
		{
			($kegg_disease_id) = $_ =~ /(H[0-9]{5})/;
		}

		## Gather the Name
		if ( $_ =~ '^NAME') 
		{
			$_ =~ s/^NAME\s*//;
			$name = $_;
			$in_name = 1;
		}
		
		## 
		if ( $_ =~ '^\s' and $in_name eq "1" ) 
		{
			$_ =~ s/\s*//;
			$name = "$name $_";
		}
		
		## Gather the DESCRIPTION
		if ( $_ =~ '^DESCRIPTION') 
		{
			$_ =~ s/^DESCRIPTION\s*//;
			$description = $_;
			## We have gathered all the NAME lines
			## Therefore no longer in the NAME section
			$in_name = 0;
		}
		
		## Gather the CATEGORY
		if ( $_ =~ '^CATEGORY') 
		{
			$_ =~ s/^CATEGORY\s*//;
			$category = $_;
		}
		
		## -- START ENV_FACTOR
		if ($in_env_factor eq "1" and $_ =~ '^\S' ) { $in_env_factor = 0; }
		## If still in drug, add the drug names
		if ($in_env_factor eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			$env_factor = "$env_factor $_";
		}
		if ( $_ =~ '^ENV_FACTOR') 
		{
			$_ =~ s/^ENV_FACTOR\s*//;
			$env_factor = $_;
			$in_env_factor = 1;
		}
		## -- END ENV_FACTOR
		
		## -- START COMMENT
		if ($in_comment eq "1" and $_ =~ '^\S' ) { $in_comment = 0; }
		## If still in drug, add the drug names
		if ($in_comment eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			$comment = "$comment $_";
		}
		if ( $_ =~ '^COMMENT' )
		{
			$_ =~ s/^COMMENT\s*//;
			$comment = $_;
			$in_comment = 1;
		}
		## -- END COMMENT
		
		## -- START PATHWAY
		if ($in_pathway eq "1" and $_ =~ '^\S' ) { $in_pathway = 0; }
		## If still in drug, add the drug names
		if ($in_pathway eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			push_pathway_array($_);
		}
		if ( $_ =~ '^PATHWAY') 
		{
			$_ =~ s/^PATHWAY\s*//;
			push_pathway_array($_);
		}
		
		## We need to find the end of the GENE list, which 
		## is denoted by a line that starts with a non-whitespace 
		## character after the GENE line -- then the GENE lines
		## have been passed - therefore, no longer in gene
		if ($in_gene eq "1" and $_ =~ '^\S' ) { $in_gene = 0; }
		
		## If still in gene, add the gene names
		if ($in_gene eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			push_gene_array($_);
		}
		
		## GENE
		if( $_ =~ '^GENE' )
		{
			$_ =~ s/^GENE\s*//;
			push_gene_array($_);
			$in_gene = 1;			
		}
		
		## -- START DRUG
		if ($in_drug eq "1" and $_ =~ '^\S' ) { $in_drug = 0; }
		## If still in drug, add the drug names
		if ($in_drug eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			push_drug_array($_);
		}
		
		## DRUG
		if( $_ =~ '^DRUG' )
		{
			$_ =~ s/^DRUG\s*//;
			push_drug_array($_);
			$in_drug = 1;			
		}
		## -- END DRUG
		
		## -- START MARKER
		if ($in_marker eq "1" and $_ =~ '^\S' ) { $in_marker	 = 0; }
		## If still in drug, add the drug names
		if ($in_marker eq "1" and $_ =~ '^\s' )
		{
			$_ =~ s/\s*//;
			push_marker_array($_);
		}

		if( $_ =~ '^MARKER' )
		{
			$_ =~ s/^MARKER\s*//;
			push_marker_array($_);
			$in_marker = 1;			
		}
		## -- END MARKER
		
		## -- START REFERENCE
		if( $_ =~ '^REFERENCE' )
		{
			$_ =~ s/REFERENCE\s*//;
			my ($reference_tag) = $_ =~ /(\(.*\))/;
			if (! defined $reference_tag) { $reference_tag = ""; }
			$reference_tag =~ s/[\(\)]//g;
			$_ =~ s/\s*\(.*\)//;
			my $pmid = $_;
			push @reference, "$pmid,$reference_tag";
		}
		## -- END REFERENCE
	}
}


## Private Subroutines
sub push_gene_array
{
my ($symbol, $kegg_orthology_id, $kegg_gene_id); ## Fields for the keggGene table
	my ($line) = @_;
	$line =~ s/(\(.*\s*\))//;
	$line =~ s/\s*//;
	($symbol) = $line =~ /(\S*)/;
	($kegg_orthology_id) = $line =~ /(KO:K[0-9]*)/i;
	($kegg_gene_id) = $line =~ /(HSA:[0-9]*)/i;
	## Some records might not have all the information - Mark them as NA
	if (! defined $kegg_orthology_id) { $kegg_orthology_id = "NA"; }	
	if (! defined $kegg_gene_id) { $kegg_gene_id = "NA"; }
	
	## Push onto the array
	push @gene, "$symbol,$kegg_orthology_id,$kegg_gene_id";
}

sub push_drug_array
{
	my ($drug, $kegg_drug_id); ## Fields for the keggDrug table
	my ($line) = @_;
	$line =~ s/\s*//;
	($kegg_drug_id) = $line =~ /(DR:[A-Z][0-9]*)/i;
	$line =~ s/\s*(\[.*\s*\])//;
	$drug = $line;
	## Some records might not have all the information - Mark them as NA
	if (! defined $kegg_drug_id) { $kegg_drug_id = "NA"; }		
	## Push onto the array
	push @drug, "$drug,$kegg_drug_id";
}

sub push_pathway_array
{
	my ($pathway, $pathway_description);
	my $line = @_;
	#($pathway) = $_ =~ /(hsa[0-9]{5})|(ko[0-9]{5})/;
	($pathway) = $_ =~ /(hsa[0-9]{5})/;
	## There are some pathways with kegg orthology ids
	if (! defined $pathway) 
	{ 
		($pathway) = $_ =~ /(ko[0-9]{5})/; 
		$_ =~ s/(ko[0-9]{5})//;
	}
	## Remove the hsa values
	$_ =~ s/(hsa[0-9]{5})//;
	$_ =~ s/(\(.*\))//;
	$_ =~ s/^\s*//;
	$pathway_description = $_;
	## Some records might not have all the information - Mark them as NA
	if ($pathway_description eq "") { $pathway_description = "NA"; }		
	## Push onto the array
	push @pathway, "$pathway,$pathway_description";
}

sub push_comment_array
{
	my ($pathway, $pathway_description);
	my $line = @_;
	#($pathway) = $_ =~ /(hsa[0-9]{5})|(ko[0-9]{5})/;
	($pathway) = $_ =~ /(hsa[0-9]{5})/;
	## There are some pathways with kegg orthology ids
	if (! defined $pathway) 
	{ 
		($pathway) = $_ =~ /(ko[0-9]{5})/; 
		$_ =~ s/(ko[0-9]{5})//;
	}
	## Remove the hsa values
	$_ =~ s/(hsa[0-9]{5})//;
	$_ =~ s/(\(.*\))//;
	$_ =~ s/^\s*//;
	$pathway_description = $_;
	## Some records might not have all the information - Mark them as NA
	if ($pathway_description eq "") { $pathway_description = "NA"; }		
	## Push onto the array
	#push @reference, "$pathway,$pathway_description";
}

sub push_marker_array
{
	my ($marker, $marker_description, $marker_id); ## Fields for the keggMarker table
	my ($line) = @_;
	$line =~ s/\s*//;
	($marker_description) = $line =~ /(\(.*\))/i;
	($marker_id) = $line =~ /(\[.*\])/;
	$line =~ s/\s*(\[.*\s*\])//;
	$line =~ s/\s*(\(.*\s*\))\s*//;
	$marker = $line;
	## Some records might not have all the information - Mark them as NA
	if ($marker eq "") { $marker = "NA"; }		
	if (! defined $marker_id) { $marker_id = "NA"; }		
	if (! defined $marker_description) { $marker_description = "NA"; }		
	$marker_description =~ s/[\(\)]//g;
	
	## Push onto the array
	#push @marker, "$,$kegg_drug_id";
	
	## There could be several marker ids involved in the marker
	my @marker_id_fields = split " ", $marker_id;
	foreach(@marker_id_fields)
	{
		$_ =~ s/[,\[\]]//g;
		push @marker, "$marker,$_,$marker_description";
	}
	$test++;
}
close(FILE);
$dbh->disconnect();
