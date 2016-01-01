#!/usr/bin/env perl

package word_search::GeneWords;
use warnings;
use strict;
use word_search::Drug;
use word_search::Gene;
use word_search::DBResult;
use Scalar::Util;

our @EXPORT_OK = qw ( getGeneList getDrugList);
## Set up the database handle using the

use SQL::CONN::db_connect;
use word_search::WordContext;
use word_search::DocumentContext;
use word_search::word_index qw( is_reference_line id_to_line_number get_line 
			get_word_to_id_array set_word_hash id_to_line_characters is_word_in_reference_section);

my $MIN_CHARACTER_LENGTH = 2;
my (%gene_list, %drug_list, $acronym_hash, %special_gene_names, %all_caps_symbols, %gneomeGenes, %synonym_list, %resultGenes);
my $dbh = SQL::CONN::db_connect->get_connection();

## Constructor
sub new
{
	my $class = shift;
	my $self = { _word_index => shift,
				 _line_index => shift,
				 _word_to_id => shift };
	my $documentContext = word_search::DocumentContext->new($self->{_word_index},
		$self->{_line_index}, $self->{_word_to_id});
	($acronym_hash) = $documentContext->getAcronyms;
	
	## Get the special gene names hash setup
	## The special gene names hash contains a linking of
	## regular gene symbol (key) to a special context gene
	## name
	## ABL1 is used in a special context BCR-ABL
	$special_gene_names{"ABL1"} = "ABL";
	$special_gene_names{"PIK3CA"} = "PI3k";
	## Add more here...
	
	## Prepare the gene_list hash with all the gene symbol from the database
	my $gneome_id_query = "select symbol, gneomeID, taxID from GeneMain"; # two choices are: view_allsymbols and genemain
	my $gneome_id_query_handle = $dbh->prepare($gneome_id_query);
	$gneome_id_query_handle->execute();
	while (my @row = $gneome_id_query_handle->fetchrow_array) {
		my $symbol = $row[0];
		$symbol =~ s/^_//; ## Remove underscores at the beginning, which could be from some data
		my $gneomeID = $row[1];
		my $taxonomy = $row[2];
		## Create a class entry for each gene word
		my $gene = word_search::Gene->new($symbol, $taxonomy, $gneomeID);
		## Possible refactor point: Does this hash get to consume too much memory?
		## Insert into the gneomeGenes hash with the ID as the gneomeID
		$gneomeGenes{$gneomeID} = $gene;
		
		## Check if the gene_list hash already contains the gene symbol
		## If so, update the gneomeID's
		## If not, add a new record
		if( exists $gene_list{$symbol} )
		{
			$gneomeID .= "|$gene_list{$symbol}";
		}
		$gene_list{$symbol} = $gneomeID;
		## Add any special context gene names
		if ( exists $special_gene_names{$row[0]} ) { $gene_list{$special_gene_names{$row[0]}} = $row[1]; }
	}

	
	## Prepare the synonym_gene_list hash with the symbols from the database
	my $gneome_synonym_query = "select symbol, gneomeID, taxID from GeneSynonym"; # two choices are: view_allsymbols and genemain
	my $gneome_synonym_query_handle = $dbh->prepare($gneome_synonym_query);
	$gneome_synonym_query_handle->execute();
	while (my @row = $gneome_synonym_query_handle->fetchrow_array) {
		my $symbol = $row[0];
		$symbol =~ s/^_//; ## Remove underscores at the beginning, which could be from some data
		my $gneomeID = $row[1];
		my $taxonomy = $row[2];
		## Create a class entry for each gene word
		my $gene = word_search::Gene->new($symbol, $taxonomy, $gneomeID);
		## Possible refactor point: Does this hash get to consume too much memory?
		## Insert into the gneomeGenes hash with the ID as the gneomeID
		$synonym_list{"\U$symbol"} = $gneomeID;
	}
	## Prepare the drug_list hash with all the drug names from the database
	## REFACTOR: create a view to find all the drug names
	my $drug_query = "select drugname, accessionid, source from DrugMain where length(drugname) > 4";
	my $drug_query_handle = $dbh->prepare($drug_query);
	$drug_query_handle->execute();
	while (my @row = $drug_query_handle->fetchrow_array) {
		my $drug = word_search::Drug->new($row[0], $row[1], $row[2]);
		$drug_list{"\U$row[0]"} = $drug;
	}
	## Get the all caps gene symbol list
	my $all_caps_query = "SELECT symbol FROM util_all_caps_symbols";
	my $all_caps_query_handle = $dbh->prepare($all_caps_query);
	$all_caps_query_handle->execute();
	while (my @row = $all_caps_query_handle->fetchrow_array) {
		## gene_list{gneomeID} = symbol;
		$all_caps_symbols{$row[0]} = $row[1];
	}
	$dbh->disconnect();
	bless $self, $class;
	return $self;	
}

sub getLongestWordThreshold
{
	my ($self) = @_;
	return $self->{_longest_word_threshold};
}

## Return the drug list array
sub getDrugList
{
	return \%drug_list;
}
## Input: A word to be searched for
## The logic checks whether the word is a gene symbol or a drug name
## Output: If the word is a gene - "gene"
##			If the word is a drug - "drug"	
sub tag
{
	## Get the search word from the first passed parameter
	my $self = $_[0];
	my ($search_word) = $_[1];
	## File extensions such as .CEL are found as gene names
	## There is no point of analyzing that word any further... 
	if ( $search_word =~ /^\./) { print STDERR "word found as extension: $search_word\n"; return "none"; }
	my $word_id = $_[2];
	my $longest_word_threshold = $_[3];
	#if(length $search_word <= $longest_word_threshold && $search_word ne "Notfound")
	if(length $search_word <= $longest_word_threshold)
	{
		## Only use the word, if it is greater than 1 character
		if((length $search_word) > $MIN_CHARACTER_LENGTH ) 
		{
#print "Search word\t$search_word\n";
			## REFACTOR: CHANGE THE RETURN VALUES TO BE HASHES..
			## THE KEY WILL BE "none", "gene" or "drug"
			## THE VALUE WILL BE THE OBJECT REPRESENTING THE DBRESULT
			
			## REFACTOR: INTRODUCE A GNEOMEID TO WORD ID MAPPING HASH
			## WHICH COULD BE USED AT A TIME WHERE WE WILL ANNOTATE EACH
			## INDIVIDUAL WORD, MAYBE MULTIPLE TIMES WITHIN A DOCUMENT
			
			## Check whether the word is a gene:
			## Compare it to the HUGO_gene_list array to find a match
			#if( (exists $gene_list{"\U$search_word"}) && ($self->isFalsePositive("\L$search_word", $word_id) eq "false")) { return "gene"; }
			if( (exists $gene_list{"\U$search_word"}) && ($self->isFalsePositive($search_word, $word_id) eq "false")) 
			{ 
				## Compile the class to be returnedreturn "gene"; 
				my $geneResult = word_search::DBResult->new("gene", $search_word, $gene_list{$search_word});
				
				## For each of the gneomeID's for the genes found
				## add them to the geneResults array
				my $idList = $gene_list{"\U$search_word"};
				## Split, if there are multiple ids in the list
				if ( defined $idList)
				{
					my @fields = split(/\|/, $idList);
					foreach (@fields) { $self->addGeneToResultGenes($_); }
				}
				## Else, it is a single id and add to result genes list
				#else { $self->addGeneToResultGenes($idList); }
				return $geneResult;
			}
			if( (exists $synonym_list{"\U$search_word"}) && ($self->isFalsePositive($search_word, $word_id) eq "false")) 
			{
				## Compile the class to be returnedreturn "gene"; 
				my $geneResult = word_search::DBResult->new("gene", $search_word, $synonym_list{$search_word});
				
				## For each of the gneomeID's for the genes found
				## add them to the geneResults array
				my $idList = $synonym_list{"\U$search_word"};
				## Split, if there are multiple ids in the list
				if ( defined $idList)
				{
					my @fields = split(/\|/, $idList);
					foreach (@fields) { $self->addGeneToResultGenes($_); }
				}
				## Else, it is a single id and add to result genes list
				#else { $self->addGeneToResultGenes($idList); }
				return $geneResult;
			}
			elsif( exists $drug_list{"\U$search_word"} ) { return $drug_list{"\U$search_word"}; }
			else {  return "none"; }
		}
		else {return "none"; } ## blank words..		
	}
	else { return "none" } ## words longer than the threshold
}

## Input: word that was identified as a gene
## This function performs some tests to identify whether a word is not
## really gene, given its context
## Output: 	"false" if it is not a false positive - an actual gene
##			"true" if it is a false positive - not a gene in this context
sub isFalsePositive
{
	## Get the search word from the first passed parameter
	my $self = $_[0];
	my ($search_word) = $_[1];
	my ($word_id) = $_[2];
	my $wordContext = word_search::WordContext->new($self->{_word_index});

	## START -- False positive removal
	## A codon identified as a gene
	
	## Get the line of words for future false positive tests...
	my $line_number = id_to_line_number($word_id);
	my $line = get_line($line_number);
	
	if ( ( $search_word =~ /\b[ACGTUacgtu][ACGTUacgtu][ACGTUacgtu]\b/ ) &&
		($wordContext->isCodonContext($word_id) eq "true" )) 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "\t$search_word\tCodon context\n"; 
		return "true"; 
	}
	elsif ( length $search_word <= 5 && is_reference_line($line) eq "true") 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\treference_line_context\n";
		return "true"; 
	}
	## Initials identified as a gene
	elsif ( (length $search_word <= 2) && 
			($wordContext->isNameContext($word_id) eq "true")) 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\tauthor_name_context\n";
		return "true"; 
	}
	## Supplementary words are found as genes
	elsif ( ( $search_word =~ /(S\d)/ ) && 
			( $wordContext->isSupplementary($word_id) eq "true") ) 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "$search_word\tSupplementary section context\n";
		return "true"; 
	}
	## Codes in addresses are found as genes
	elsif ( $wordContext->isAddress($word_id) eq "true") #) 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "\t$search_word\tAddress context\n";
		return "true"; 
	}
	elsif ( $wordContext->isLowCharacter($word_id) eq "true")
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "$search_word\tLow number of characters on line\n";
		return "true";
	}
	## Words in mate pair context found as genes
	elsif ( (length $search_word <= 2) &&
			($wordContext->isMatePairContext($word_id) eq "true"))
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "\t$search_word\tMate pair context\n";
		return "true";
	}
	## Word "GC" found as a gene
	elsif ( (length $search_word <= 2) && ( $search_word =~ /[GC]/i ) &&
			($wordContext->isGCContext($word_id) eq "true"))
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "$search_word\tGC context\n";
		return "true";
	}
	## Check if an acronym is found as a gene
	elsif ( $self->isAcronym($search_word) eq "true")
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\tacronymcontext\n";
		return "true";
	}
	## Check is a roman numeral is found as a gene
	elsif ( (length $search_word <= 3) && ( $search_word =~ /^[IVXivx]{2}/ )
		&& ( $wordContext->isRomanNumeral($word_id) eq "true") )
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "\t$search_word\tRoman numeral context\n";
		return "true";
	}
		## Check whether if the text CHR refers to a chromosome
	elsif ( "\L$search_word" eq "chr" &&
			( $self->{_word_index}{($word_id+1)}->getSearchWord() =~ /^[0-9]/ ||
			  $self->{_word_index}{($word_id+1)}->getSearchWord() =~ /^[XxYy]/))
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified false positive\t";
		print STDERR "\t$search_word\tchr identified as a gene\n";
		return "true";
	}
	## Check if a unit notation was found as a gene
	elsif ( (length $search_word <= 3) && ( $wordContext->isUnitNotation($word_id) eq "true") )
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\tunit_notation_context\n";
		return "true";
	}
	## Check if the gene symbol found belongs to an abbreviated set of words
	elsif ( $wordContext->isAbbreviatedName($word_id) eq "true" )
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\tabbreviated_word_set_context\n";
		return "true";
	}
	## Check if the gene symbol has to be at least marked with a upper case first letter
	## REFACTOR: test this carefully
	elsif ( exists $all_caps_symbols{"\U$search_word"})
	{
		my $is_common = "false";
		if  ($search_word =~ /^[a-z]/) { $is_common = "true"; }
		## Check whether the word is the first word of a sentence.
		## If so, the gene symbol should be all caps. Otherwise words
		## such as Large will be identified as genes
		if( $wordContext->isFirstWord($word_id) eq "true" && 
			$search_word !~ /[A-Z]/) { $is_common = "true"; }
		if( $is_common eq "true" )
		{
			print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
			print STDERR "$search_word\tlower_case_context\n";
			return "true";
		}
	}
	## However, if the all caps word is the first word in the line, it has to be all CAPS
	elsif ( is_word_in_reference_section($word_id, $search_word) eq "true" )
	{
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_false_positive\t";
		print STDERR "$search_word\tword_in_reference_section_context\n";
		return "true";
	}
	## END -- False positive removal
	else 
	{ 
		print STDERR "word_search::GeneWords::isFalsePositive\tIdentified_true_positive\t";
		print STDERR "$search_word\tpassed_all_false_positive_tests\n";
		return "false"; 
	}
}

sub isAcronym
{
	my $self = $_[0];
	my ($search_word) = $_[1];
	foreach (keys %$acronym_hash)
	{
		if ( $search_word eq $_ ) 
		{ 
			## This is disbaled, as a lot of false
			## negatives are created due to acronyms
			return "false";
			## uncomment following line if need to enable
			##return "true"; 
		}
	}
	return "false";
}

## Does a term exist in gene list
## This is only used as a last check before a word is
## inserted into the common words table
## This will make sure that a gene related word will never be
## inserted into the DB as a common word
sub isNotCommonWord
{
	my $self = $_[0];
	my ($search_word) = $_[1];
	if ( exists $gene_list{$search_word} ) { return "true"; }
	if ( exists $drug_list{$search_word} ) { return "true"; }
	else { return "false"; }
}

## This subroutine adds a gneomeID to the hash of results
## This is a comprehensive list of all the genes...
sub addGeneToResultGenes
{
	my $self = $_[0];
	my $gneomeID = $_[1];
	$resultGenes{$gneomeID} = $gneomeGenes{$gneomeID};	
}

sub getResultGenes
{
	return \%resultGenes;
}
return "true";
