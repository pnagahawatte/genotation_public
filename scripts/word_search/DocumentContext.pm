#!/usr/bin/env perl
package word_search::DocumentContext;
use strict;
use warnings;
use word_search::word_index qw(set_word_hash id_to_line_characters);
use Exporter qw(import);
#use DB_File;

our @EXPORT_OK = qw(get_context codon_context);

my $ACRONYM_MATCH_THRESHOLD=.8; ## Holds the cutoff to determine the acronym match
#my ($country_list_db) = gneome_db::GneomeHashDB->getDB("country_list");
#my $country_list = gneome_db::HashDB->new();

sub new
{
	my $class = shift;
	my $self = { _word_index => shift,
				 _line_index => shift,
				 _word_to_id => shift };
	bless $self, $class;
	return $self;
}

## Input: A search word
## The logic checks through the word index to find
## whether the word is defined within paranthesis as an
## acronym to a term 
sub isAcronym
{
	my $self = $_[0];
	my $id = $_[1];
	my $wordContext = word_search::WordContext->new($self->{_word_index});
	#my @fields = split '\|', $self->{_word_index}->{$id};
	#my $acronym_candidate = $fields[0];
	#$acronym_candidate =~ s/\(//;
	#$acronym_candidate =~ s/\)//;
	
	my $acronym_candidate = $self->{_word_index}{$id}->getSearchWord();
	my ($words) = $wordContext->getWords($id);
	my ($i, @initials, @candidates, @reverse_candidates, @reverse_initials, $word_line);
	@candidates = split //, $acronym_candidate;
	#for ($i = (($#$words/2)-1); $i>=0; $i--)		
	for ($i = 0; $i <= ($#$words/2); $i++)		
	{
		## Inspect the neighboring words to see if acronym
		## What is the length of the word?
		#my $candidate_char = substr $acronym_candidate, $i,1;
		push @initials,substr $words->[$i], 0,1;
		$word_line .= $words->[$i] . ",";
	}
	@reverse_initials = reverse @initials;
	@reverse_candidates = reverse @candidates;
	my $match_count = 0;
	for(my $c = 0; $c <= $#reverse_candidates; $c++ )
	{
		if ( $reverse_candidates[$c] =~ /[0-9]/ ) { return "false"; }
		else
		{
			#for (my $i = (($#$words/2)-1); $i>=0; $i--)
			for (my $i = 0; $i < $#reverse_initials; $i++)
			{
				#if ( $reverse_initials =~ /[0-9]/ ) { splice(@reverse_initials, $i, 1); }
				if (lc $reverse_initials[$i] eq lc $reverse_candidates[$c]) 
				{ 
					## Remove the first match
					splice(@reverse_initials, $i, 1);
					$match_count++;
				}
			}
		}
	}
	if ( $match_count > ( $#candidates * $ACRONYM_MATCH_THRESHOLD)) { return "true"; }
	else { return "false"; }
}

sub getAcronyms
{
	my $self = $_[0];
	my %acronym_hash;
	my $acronym_count = 1;
	foreach (@{$self->{_word_to_id}})
	{
		my @fields = split '\|', $_;
		my $acronym_word = $fields[0];
		my $acronym_word_id = $fields[1];
		## Common notation is to include the acronyms within parantheses
		## Therefore, only consider the words that are within parantheses
		if (( $acronym_word =~ /^\(.*\)$/ ) && ( $self->isAcronym($acronym_word_id) eq "true" ))
		{
			print STDERR "word_search::DocumentContext::getAcronyms Found Acronym : $fields[0]\n";
			## Acronym standards are documented here: http://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Abbreviations
			## Remove the plural indicator : lower case "s"
			$acronym_word =~ s/s\)$//;
			$acronym_word =~ s/^\(//;
			$acronym_word =~ s/\)$//;
			## Do not add single character acronyms
			if ( length $acronym_word > 1 ) {$acronym_hash{$acronym_word} = $acronym_word_id; }
		}
	}
	return \%acronym_hash;
}