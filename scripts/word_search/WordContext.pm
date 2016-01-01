#!/usr/bin/env perl
package word_search::WordContext;
use strict;
use warnings;
use word_search::word_index qw(set_word_hash id_to_line_characters);
use Exporter qw(import);
use SQL::CONN::db_connect;

my $NEIGHBOR_WORD_BOUNDARY = 8;
my $LOW_CHARACTER_THRESHOLD = 3;

our @EXPORT_OK = qw(get_context codon_context);

#my ($country_list_db) = gneome_db::GneomeHashDB->getDB("country_list");
my $country_list = gneome_db::HashDB->new();

sub new
{
	my $class = shift;
	
	## Get the country list from the DB
	my %countryList;
	my $dbh = SQL::CONN::db_connect->get_connection();
	my $countryListQuery = "select text from util_country_names";
	my $sth = $dbh->prepare($countryListQuery);
	$sth->execute();
	my $id = 1;
	while (my @row = $sth->fetchrow_array) {
		my $countryText = $row[0];
		$countryList{$countryText} = $id;
		$id++;
	}
	$dbh->disconnect();
	my $self = { _word_index => shift,
				 _country_list => \%countryList};
	bless $self, $class;
	return $self;
}

## Input: An id for a particular word in the hash
## The logic checks for up and downstream words (#
## specified by $NEIGHBOR_WORD_BOUNDARY) to check if the
## given word is in the context of a codon string
sub isCodonContext
{
	my $self = $_[0];
	my $id = $_[1];

	my $start_id = $id-$NEIGHBOR_WORD_BOUNDARY;
	my $end_id = $id+$NEIGHBOR_WORD_BOUNDARY; 
	my $range = $end_id - $start_id;
	## Get the words array
	my ($words) = $self->getWords($id);
	my ($codon_count, $prime_notation) = (0,0);
	## What is the nature of the surrounding words?
	foreach(@$words)
	{
		if ($_ =~ /([ACGTUacgtu][ACGTUacgtu][ACGTUacgtu])/) {$codon_count++; }
		if ($_ =~ /\b3'\b|\b5'\b/ ) { $prime_notation = 1; }
	}
	## Are surrounding words codons?
	if ((($codon_count/$range) > .3)) {return "true";}
	elsif((($codon_count/$range) > .1) && ($prime_notation == 1)) {return "true";}
	else {return "false";}
}

## Input: An id for a particular word in the hash
## The logic checks for up and downstream words
## for a name context
sub isNameContext
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
	my $comma_count = 0;
	my ($has_et, $has_al) = ("false", "false");
	foreach(@$words)
	{
		## EXPAND THE RULES TO MAKE THIS DECISION
		## Presence of commas around initials are a good indication of names
		if ( $_ =~ /[\.,]/ ) { $comma_count++; }
		if ($_ eq "et" ) { $has_et = "true"; }
		if ($_ eq "al" || $_ eq "al." ) { $has_al = "true"; }
	}
	## If there is an indication of names, return true
	# if ( $has_et eq "true" && $has_al eq "true" ) { return "true"; }
	if ( $has_et eq "true" && $has_al eq "true" ) { return "true"; }
	elsif ( ($comma_count / ($NEIGHBOR_WORD_BOUNDARY*2)) > .3 ) { return "true"; }
	else { return "flase"; }
}

## This method checks for a "Supplementary details" context
## for a given word
sub isSupplementary
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
	foreach(@$words)
	{
		if ( $_ =~ /Supplement/i ) { return "true"; }
		elsif ( $_ =~ /Table/i ) { return "true"; }
		elsif ( $_ =~ /Fig/i ) { return "true"; }
	}
	return "false";
}

## This method checks whether a word should be interpreted as a 
## Roman numeral
sub isRomanNumeral
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
#print " Roman numeral checking:\t";
	foreach(@$words)
	{
		## Are there any other Roman numeral in surrounding words?
		## REFACTOR: Add more conditions
		if ( $_ =~ /^[IVXivx]{2}/i ) { return "true"; }
	}
#print "\n";
	return "false";
}

## This method checks for a "Address line" context
## for a given word
## REFACTOR: Move to LineContext.pm
sub isAddress
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
	my ($is_institute, $is_country, $is_postal_code) = ("false","false", "false");
	foreach(@$words)
	{
		## Look for common words recurrent in address lines
		if ( $_ =~ /Institute|Hospital|University|center|department|project|college/i ) { $is_institute = "true"; } 
		elsif ( exists $self->{_country_list}->{$_} ) { $is_country = "true"; } 
		## British address codes
		elsif ( $_ =~ /\b([a-zA-Z]{2}[0-9]{1})\b|\b([0-9]{1}[a-zA-Z]{2})\b/ ) { $is_postal_code = "true"; } 
		# US 
		elsif ( $_ =~ /\b([A-Z]{2})\b|\b([0-9]{5})\b/ ) { $is_postal_code = "true"; }
	}

	if ( $is_institute eq "true" && $is_country eq "true" ) { return "true"; }
	if ( $is_postal_code eq "true" && $is_country eq "true" ) { return "true"; }
	if ( $is_institute eq "true" && $is_postal_code eq "true" && $is_country eq "true" ) { return "true"; }
	return "false";
}
## This method checks for lines with less characters
sub isLowCharacter
{
	my $self = $_[0];
	my $id = $_[1];
	## If the character count is less than the threshold, return true
	if (id_to_line_characters($id) < $LOW_CHARACTER_THRESHOLD ) { return "true"; }
	## If the word has one letter and numbers, it is more likely that it is a categorization 
	## notation. Therefore, consider a higher threshold
	elsif ( ($self->{_word_index}{$id}->getSearchWord =~ /(^[A-Za-z]{1}[0-9])/) && 
		(id_to_line_characters($id) < ($LOW_CHARACTER_THRESHOLD+2) )) { return "true"; }
	else { return "false"; }
}

## This method checks whether 2 character words are in 
## a context where mate pairs are denoted - ex: F3 and R3
sub isMatePairContext
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
	my $evidence_count = 0;
	foreach(@$words)
	{
		## SOLiD forward and reverse strands
		if ( $_ =~ /R[0-9]/i ) { return "true"; }
		elsif ( $_ =~ /mate/i ) { $evidence_count++; }
		elsif ( $_ =~ /pair/i ) { $evidence_count++; }
		elsif ( $_ =~ /map/i ) { $evidence_count++; }
		elsif ( $_ =~ /tag/i ) { $evidence_count++; }
	}
	if ( $evidence_count > 1 ) { return "true"; }
	else { return "false"; }
}

## This method checks whether "GC" text is in a non-gene context
sub isGCContext
{
	my $self = $_[0];
	my $id = $_[1];
	my ($words) = $self->getWords($id);
	my $evidence_count = 0;
	foreach(@$words)
	{
		if ( $_ =~ /rich/i ) { $evidence_count++; }
		elsif ( $_ =~ /region/i ) { $evidence_count++; }
		elsif ( $_ =~ /island/i ) { $evidence_count++; }
		elsif ( $_ =~ /shore/i ) { $evidence_count++; }
		elsif ( $_ =~ /content/i ) { $evidence_count++; }
		elsif ( $_ =~ /percent/i ) { $evidence_count++; }
	}
	if ( $evidence_count > 0 ) { return "true"; }
	else { return "false"; }
}

## This method checks whether a 2 letter "unit" notation was found
## as a gene
sub isUnitNotation
{
	my $self = $_[0];
	my $id = $_[1];
	my $previous_word = "";
	## Check if the previous word is a number
	#my $word_fields = 
	#my @fields = split '\|', $self->{_word_index}->{($id-1)};
	#my $previous_word = $fields[0];
	if (defined $self->{_word_index}{($id-1)}) 
	{
		$previous_word = $self->{_word_index}{($id-1)}->getSearchWord();
	}
	if ($previous_word =~ /^[0-9]*$/ && $previous_word ne "") { return "true"; }
	## If the previous word does not have any letters, then identify as a unit notation
	else { return "false"; }

}

## This method checks whether a given word is the first os
## a sentence
sub isFirstWord
{
	my $self = $_[0];
	my $id = $_[1];
	## Check if the previous word ends with a period
	my $previous_word = $self->{_word_index}{($id-1)}->getSearchWord();
	if ($previous_word =~ /^.*\.$/) { return "true"; }
	else { return "false"; }
}

## This method checks whether a word is a part of an 
## abbreviated name. Ex: "Proc. Natl. Acad. Sci."
sub isAbbreviatedName
{
	my $self = $_[0];
	my $id = $_[1];
#my @fields = split '\|', $self->{_word_index}->{$id};
	## Does this word have a period at the end of the word?
	## If not proceed, no further
#if ( $fields[0] !~ /^[A-Za-z0-9]*\.$/ ) { return "false"; }
	my $searchWord = $self->{_word_index}{$id}->getRawWord;
	if ( $searchWord !~ /^[A-Za-z0-9]*\.$/ ) { return "false"; }
	## If it has a period at the end proceed...
	## Check if the previous word ends with a period
#my @fields_prev = split '\|', $self->{_word_index}->{($id-1)};
#my @fields_next = split '\|', $self->{_word_index}->{($id+1)};
#	if ( $fields_prev[0] =~ /^[A-Za-z0-9]*\.$/ ) { return "true"; }
#	elsif ( $fields_next[0] =~ /^[A-Za-z0-9]*\.$/ ) { return "true"; }
	my $prevSearchWord = $self->{_word_index}{($id-1)}->getRawWord;
	my $nextSearchWord = $self->{_word_index}{($id+1)}->getRawWord;
	if ( $prevSearchWord =~ /^[A-Za-z0-9]*\.$/ ) { return "true"; }
	elsif ( $nextSearchWord =~ /^[A-Za-z0-9]*\.$/ ) { return "true"; }
	else { return "false"; }
}

## Private method to be used in multiple methods
## This gets a range of words from the word_index
sub getWords
{
	my $self = $_[0];
	my $id = $_[1];
	set_word_hash(\%{$self->{_word_index}});
	## Extract the
	my $start_id = $id-$NEIGHBOR_WORD_BOUNDARY;
	my $end_id = $id+$NEIGHBOR_WORD_BOUNDARY; 
	my $range = $end_id - $start_id;
	## Check the user input
	#if( $start_id > $end_id || $start_id < 0 || $end_id < 0 ) { pr
	## If the end is beyond the last index of the has, set the end to be
	## the last index of the hash
	if ($end_id>keys %{$self->{_word_index}} ) { $end_id = keys %{$self->{_word_index}}; }
	my @words;
	
	while ($start_id<=$end_id && $start_id>=0)
	{
		#my @fields = split '\|', $self->{_word_index}->{$start_id}; $start_id++;
		## Make sure that we do not seek an index that is out of bounds...
		my $searchWord = "";
		if (defined $self->{_word_index}{$start_id})
			{ $searchWord = $self->{_word_index}{$start_id}->getSearchWord(); }
		$start_id++;
		if ($searchWord ne "" ) {push @words, $searchWord; }
	} 
	return \@words;
}