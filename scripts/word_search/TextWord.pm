#!/usr/bin/env perl

package word_search::TextWord;
use warnings;
use strict;

## This module is a struct which holds all the necessary
## information about an individual word in a text document

## The struct contains the following fields:
##	1. raw word
##	2. search word
##	3. line number
##	4. word number
##	5. character count

sub new
{
	my $class = shift;
	my $rawWord = shift;
	my $self;
	my $searchWord = prepareSearchWord($class, $rawWord);
	$self = { _raw_word => $rawWord,
				 _search_word => $searchWord,
				 _line_number => shift,
				 _word_number => shift,
				 _character_count => length($rawWord),
				 _search_db => shift}; ## This is a true / false answer
				 ## whether it should be searched against the DB};
	bless $self, $class;
	return $self;
}

sub getRawWord
{
	my $self = $_[0];
	return $self->{_raw_word};
}

sub getSearchWord
{
	my $self = $_[0];
	return $self->{_search_word};
}

sub getLineNumber
{
	my $self = $_[0];
	return $self->{_line_number};
}

sub getWordNumber
{
	my $self = $_[0];
	return $self->{_word_number};
}

sub getCharacterCount
{
	my $self = $_[0];
	return $self->{_character_count};
}

sub getSearchDB
{
	my $self = $_[0];
	return $self->{_search_db};
}
## This subroutine was formerly called Genewords::Cleanse
## Input: a word to be searched
## This functions cleanses the word of any commas
## whitespace, periods etc. so it could be searched against the db
sub prepareSearchWord
{
	my $self = $_[0];
	my ($searchWord) = $_[1];
#print "before cleanse: $searchWord\n";
	## Remove all the full stops, commas, question marks, exclamation points as gene symbols could
	## be followed by these characters, which would cause issues
	## downstream
	$searchWord =~ s/[,?!]$//;
	$searchWord =~ s/[():;<>+]//g;
	## Only remove periods if they are full stops
	$searchWord =~ s/\.$//;
	## Remove any lone standing numbers
	#$search_word =~ s/^[0-9]*//g;
	## Remove a slash or a hyphen if it is the last character
	$searchWord =~ s/[\/\-]$//;
	## Remove a slash and following digits that are in the end
	$searchWord =~ s/\/[0-9]+//g;
	
	## Removing dashes need a bit more scrutiny
	if ( $searchWord =~ /-/ ) 
	{ 
		my @fields = split "-", $searchWord;
		##1:
		## If the characters after the "-" in a 2 letter word (separated by -),
		## are only digits, then remove the dashes
		##2:
		## If there is only one character after the "-" in a 2 letter word(separated by -),
		## then only remove the dashes
## Possible bug - why do some of the second words get dropped?
##print STDERR "hyphen\t$searchWord\n";
		if (defined $fields[1]) { if (($fields[1] =~ /^[0-9]+$/) || (length($fields[1]) == 1)) 
			{ $searchWord =~ s/-//; } }
	}
	$searchWord =~ s/\s//g;
	return $searchWord;
}

return "true";