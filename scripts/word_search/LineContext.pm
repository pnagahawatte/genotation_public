#!/usr/bin/env perl
package word_search::LineContext;
use strict;
use warnings;
use word_search::word_index qw(set_word_hash id_to_line_characters);
use Exporter qw(import);
use DB_File;

our @EXPORT_OK = qw(get_context codon_context);

my ($country_list_db) = gneome_db::GneomeHashDB->getDB("country_list");
my $country_list = gneome_db::HashDB->new($country_list_db);

sub new
{
	my $class = shift;
	my $self = { _word_index => shift };
	bless $self, $class;
	return $self;
}

## Input: A line of text
## This subroutine tries to predict whether a line of text
## belongs to the references section or not
## Output: 	Returns 0 if predicted NOT to be a reference line
## 			returns 1 if predicted to be a reference line
sub is_reference_line
{
	my ($line) = @_;
	my @fields = split " ", $line;
	my ($word_count, $comma_count, $enumerated, $has_year, $has_page_range, 
		$has_et, $has_al, $has_journal, $has_http) 
		= (0,0,0,0,0,0,0,0,0);
	foreach(@fields)
	{
		## Remove any full stops
		$_ =~ s/\.$//;
#print "working on: $_\n";
		$word_count++;
		if( $_ =~ /,/ ) { $comma_count++; }
		## Is there a year in the line
		if ( $_ =~ /([\(]?\d{4}[\)]?$)/ ) { $has_year = 1; } #print "year: $_\n";}
		## Is the line enumerated?
		if ($_ =~ /(\d+-?\d)/ ) { $has_page_range = 1; } #print "page range $_\n";}
		if ($_ eq "et" ) { $has_et = 1; }
		if ($_ eq "al" || $_ eq "al." ) { $has_al = 1; }
		if ($_ =~ /journal/i ) { $has_journal = 1; }
		if ($_ =~ /http:\/\//i ) { $has_http = 1; }
	}
	
	## make the decision
	my $reference_points = 0;
	if ( $word_count > 0 and ($comma_count/$word_count)*100 > 10) { $reference_points++; }
	if ( $has_year eq "1" ) { $reference_points++; }
	if ( $has_page_range eq "1" ) { $reference_points++; }
	#return "$reference_points";
	
	## Is this a reference line?
	if( $has_et == 1 && $has_al == 1 ) { return 1; }
	elsif ( $has_year == 1 && $has_page_range == 1) { return 1; }
	elsif ( $has_journal == 1 && $has_page_range == 1) { return 1; }
	elsif ( $has_http == 1 ) { return 1; }
	else { return 0; }#elsif ( 
}