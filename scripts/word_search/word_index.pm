#!/usr/bin/env perl

package word_search::word_index;
use strict;
use warnings;

use Exporter qw(import);
use word_search::TextWord;
our @EXPORT_OK = qw(generate print_text get_word_hash get_line print_word_index get_test_all_words get_max_line 
set_doc_section get_doc_section get_included_section get_search_words add_tagged_word modify_text_annotation 
set_word_hash get_lines id_to_line_number print_doc_sections is_reference_line get_tagged_words 
id_to_line_characters get_line_hash get_word_to_id_array is_word_in_reference_section);
my (%word_index, %document_sections, %document_lines, %search_words, %test_all_words, @word_to_id, @tagged_words, %word_class_index);
use gneome_db::HashDB qw(print_words word_exists);

## REFACTOR IMMEDIATELY: CHANGE TO THE NEW DB METHOD
my $common_words = gneome_db::HashDB->new();
my $REF_LINE_PCT_THRESHOLD = 25;
my $MIN_CHARACTER_LENGTH = 1;
my $REF_LINE_COMMA_INITIAL_THRESHOLD = 4;

## Utility functions -- errors
## Print error for undefined word_index hash
sub print_index_error
{
	print STDERR "Error in word_search::word_index::get_included_section ";
	print STDERR "The word_index has not been generated. ";
	print STDERR "Did you forget to call word_search::word_index::generate?\n";
}

## Print error for undefined doc_section hash
sub print_doc_section_error
{
	print STDERR "Error in word_search::word_index::get_included_section ";
	print STDERR "The document_section_hash has not been generated. ";
	print STDERR "Did you forget to call word_search::word_index::set_doc_section?\n";
}


my $FIELD_SEPARATOR = " ";
## This function creates a 
sub generate
{
	## Contents of the hash is as follows
	## key : which is the position of the text within the document
	## text | line number | word position | number of characters | 
	## tag (n:None d:Drug g:Gene) | annotation (h:html x:xml t:txt n:none) |
	## context (n: None ...)
	my ($text) = @_;
	my ($id, $line_count) = (1,1);
	open(FILE, "< $text" ) or die "Can't open the text file $text: $!";
	#open(my $fh, '<:encoding(UTF-8)', $text ) or die "Can't open the text file $text: $!";

	while(<FILE>)
	{
		## Add the line to the document_lines hash
		$document_lines{$line_count}=$_;
		my $text_line = $_;
		my $is_reference_line = 0;

		chomp($_);
		my @fields = split " " , $_;
		my $word_count = 1;
		## Is this a reference line?
		if( is_reference_line($text_line) eq "true" ){ $is_reference_line = 1; }
		
		foreach(@fields)
		{
			my $character_count = length;
			
			push @word_to_id,  "$_|$id"; ## This helps to identify the word id from the text
			## Remove any full stops
			$_ =~ s/\.$//;
			
			my $textWord = word_search::TextWord->new($_,$line_count,$word_count,$character_count);
			## Each word and metadata is added to the word_class_index hash
			## The id here corresponds with the id of the following hashes:
			## %search_words
			$word_class_index{$id} = $textWord;
			## Add to the search_words hash, if decided to be a search word
			if ( ! $common_words->word_exists($textWord->getSearchWord()) && is_search_word($textWord->getSearchWord()) eq "true" ) 
				{ $search_words{ $id } = $textWord; } #$word_class_index{$id}->getSearchWord(); } 
			
			## This hash is used for testing purposes and is needed to be present
			$test_all_words{ $id } = $_;
			$word_count++;
			$id++;
		}
		$line_count++;
	}
#for my $key (keys %word_class_index) { print STDERR $word_class_index{$key}->getRawWord() . "\n"; }
	return \%word_class_index;
}

## This is the getter for the hash, which will be used 
## to share the word hash among different scripts
## Pre-requisite: 
sub get_word_hash
{
	if ( not %word_index) { print_index_error; exit(-1); }
	return \%word_index;
}

## Output: This returns the hash of search words
sub get_search_words 
{ 
	if ( not %search_words) { print_index_error; exit(-1); }
	else { return \%search_words; }
}

## 
## Output: This returns the hash of search words
sub get_word_to_id_array
{ 
	if ( not @word_to_id) { print_index_error; 	exit(-1); }
	else { return \@word_to_id; }
}

## Setter for the word_index hash
sub set_word_hash
{
	my $hash = $_[0];
	%word_index = %$hash;
}

## This subroutine prints
## the annotated text as the final product
sub print_text
{
	if ( not %word_index) { print_index_error; exit(-1); }
	my $line_number = 1;
	my $current_line = "";
	foreach(sort {$a <=> $b} keys %word_index)
	{
		my $line = $word_index{$_};
		## Parse the fields of the hash
		my @fields = split '\|' , $line;
		my $text = $fields[0];
		
		## Check for a change in line to introduce a new line
		if ($line_number != $fields[1])
		{
			$current_line =~ s/\s$//;
#			print "$current_line\n";
			$line_number = $fields[1];
			$current_line = "";
		}
		## Add the words of the sentence to the buffer
		$current_line .= $text . $FIELD_SEPARATOR;
		#chomp($word_index{$_});
		#print "$word_index{$_}\n";
	}
}

## Input: A line number
## Output: 	text from the line of document
## 			If line_number < 0 or line_number > keys %document_lines
##			return error
sub get_line
{
	my $line_number = $_[0];
	if ( $line_number < 0 || $line_number > (scalar keys %document_lines))
	{
		print STDERR "word_search::word_index::get_line - The line number provided is ";
		print STDERR "out of range\n";
		exit -1;
	}
	return $document_lines{ $line_number };
}

## Utility of get_line
## Input: a range of lines
## 1. Flag (text, id_text, details)
## 2. Start
## 3. End
sub get_lines
{
	my $flag = $_[0];
	my $start = $_[1];
	my $end = $_[2];
	my @lines;
	while($start <= $end){ push @lines, get_line($start); $start++; }
	return \@lines;
}

## Output: This script provides the largest line number
## that belongs to the document
sub get_max_line
{
	my $hash_size = keys(%word_class_index);
	## Return the line number that corresponds to the document
	return $word_class_index{$hash_size}->getLineNumber();
}

sub print_word_index
{
	## Pre-requisite:
	if ( not %word_index) { print_index_error; exit(-1); }
	foreach (sort {$a <=> $b} keys %word_index)
	{
		print $word_index{$_};
	}
}

## This function sets a document section in the hash
## The section has a line number, inclusion or exclusion (I|E)
## and whether it is a start or an end (S|E)
sub set_doc_section
{
	my ($tags) = @_;
	my @fields = split ",",$tags;
	$document_sections { $fields[0] } = $fields[1];
}

sub print_doc_sections
{
	foreach(sort {$a <=> $b} keys %document_sections)
	{
		print "$_	$document_sections{$_}\n";
	}
}

## Output: This returns the hash of lines
sub get_line_hash { return \%document_lines; }

## TEST method for QC
sub get_test_all_words { return \%test_all_words; }

## Input: id for a word metadata in the word_index hash
sub get_word_metadata
{
	my ($id) = @_;
	if ( $id < 0 || $id > (keys %word_index))
	{
		print STDERR "word_search::word_index::get_word_metadata - The id number provided is ";
		print STDERR "out of range\n";
		exit -1;
	}
	return $word_index{ $id };
}
## This function modifies fields for a particular entry
## in the word_index hash
## Input: 	1. id
##			2. field to modify (4|5|6)

## This function returns a reference to the gene list
##sub get_gene_list { return }
sub modify_text_annotation
{
	## Pre-requisite:
	if ( not %word_index) { print_index_error; exit(-1); }
	
	## Necessary fields for the modification
	my $id = $_[0];
	## Check if the provided id is in bounds 
	if( $id < 0 || $id > keys(%word_index) )
	{ 
		print "Error in word_search::word_index::modify_text_annotation ";
		print "The id provided is out of bounds for the word_index array\n";
		exit (-1);
	}
	## This indicates the fields that could be modified
	## Modifiable fields are
	## 4: Tag
	## 5: Annotation
	## 6: Context
	my $modify_index = $_[1];
	## Check if provided index is in bounds
	if ($modify_index < 4 || $modify_index > 6 )
	{
		print "Error in word_search::word_index::modify_text_annotation ";
		print "The modify_index is out of bounds - should be between 4 and 6 inclusive\n";
		exit(-1);
	}
	## This field specifies what the new text should be
	my $set_text = $_[2];
	my @fields = split '\|', $word_index { $id };
	## Make the modification
	$fields[$modify_index] = $set_text;
	## Store the modififcation in the hash
	my $new_text;
	foreach (@fields) { $new_text .= $_ . "|"; }
	$new_text =~ s/\|$//;
	## Save the changes in the hash
	$word_index { $id } = $new_text;
	#print $word_index { $id };
}

## Input: hash id for a word
## Output: The line id the word belongs to
sub id_to_line_number
{
	my $id = $_[0];
	#my @fields = split '\|', $word_index{$id};
	return $word_class_index{$id}->getLineNumber();
}

## Input : hash id for a word
## Output: How many characters are there in the line for the word id
sub id_to_line_characters
{
	my $id = $_[0];
	my $line_number = id_to_line_number($id);
	my $line = get_line($line_number);
	## Remove any newline characters from the line
	$line =~ s/\s*//g;
	return (length $line);
}
## Input: A line of text
## This subroutine tries to predict whether a line of text
## belongs to the references section or not
## Output: 	Returns 0 if predicted NOT to be a reference line
## 			returns 1 if predicted to be a reference line
sub is_reference_line
{
	my $line = $_[0];
	if (defined $line)
	{
	my @fields = split " ", $line;
	my ($word_count, $comma_count, $enumerated, $has_year, $has_page_range, 
		$has_et, $has_al, $has_journal, $has_http, $has_name_affiliation, $initials_count) 
		= (0,0,0,0,0,0,0,0,0,0,0);
	foreach(@fields)
	{
		## Remove any full stops
		#$_ =~ s/\.$//;
		$word_count++;
		if( $_ =~ /,/ ) { $comma_count++; }
		## Is there a year in the line
		if ( $_ =~ /([\(]?\d{4}[\)]?$)/ ) { $has_year = 1; } #print "year: $_\n";}
		## Is the line enumerated?
		if ($_ =~ /(\d+-\d)/ ) { $has_page_range = 1; } #print "page range $_\n";}
		if ($_ eq "et" ) { $has_et = 1; }
		if ($_ eq "al" || $_ eq "al." ) { $has_al = 1; }
		if ($_ =~ /journal/i ) { $has_journal = 1; }
		if ($_ =~ /http:\/\//i ) { $has_http = 1; }
		## Author lines have author names and their affiliation to an institute
		## ednoted by a digit
		## The last names start with an upper case letter and are followed by 
		## lower case letters, with an optional comma at the end after the 
		## digit that represents the institute
		if ($_ =~ /^[A-Z][a-z]{1,}[0-9],?$/) {$has_name_affiliation++; }
		## Initials are denoted by a period at the end of a character
		## Initials count will also give a good indication whether a line
		## is a reference line
		if (($_ =~ /^[A-Z]{1,2}\./) || ($_ =~ /^[A-Z]{1}\.[A-Za-z]{1}\./)){ $initials_count++; }
	}
	
	## Is this a reference line?
#	if( $has_et == 1 && $has_al == 1 ) { return 1; }
	if ( $has_year == 1 && $has_page_range == 1) { return "true"; } #print STDERR "has year and page range\n";
	elsif ( $has_journal == 1 && $has_page_range == 1) { return "true"; } #print STDERR "has journal and page range\n"; 
	elsif ( $has_http == 1 ) { return "true"; } #print STDERR "has http\n"; 
	elsif ( $has_name_affiliation > 0 && (($has_name_affiliation/$word_count)*100) > $REF_LINE_PCT_THRESHOLD ) { return "true"; } #print STDERR "hasnameaffiliation\n";
## Refactor: have to combine comma_count with another factor...
#	elsif ( $comma_count > 0 && (($comma_count/$word_count)*100) > $REF_LINE_PCT_THRESHOLD ) { return "true"; } #print STDERR "comma count\n"; 
	elsif ( $initials_count > 0 && (($initials_count/$word_count)*100) > $REF_LINE_PCT_THRESHOLD ) { return "true"; } #print STDERR "initials count\n"; 
	elsif ( $comma_count > $REF_LINE_COMMA_INITIAL_THRESHOLD && $initials_count > $REF_LINE_COMMA_INITIAL_THRESHOLD ) { return "true"; } #print STDERR "over-ref_threshold\n"; 
	else { return "false"; } 
	}
}

## Input : A Search word that is not a common word
## This function will indicate whether a word should be
## included as a search word
sub is_search_word
{
	my ($word) = @_;
	## Any word that starts with a digit cannot be a gene name
	if ( $word =~ /^[0-9]/ ) { return "false"; }
	## Any word that starts with a period, cannot be a gene name
	if ( $word =~ /^\./ ) { return "false"; }
	## Does the word represent initials?
	if ( $word =~ /\w{1,3},/ ) { return "false"; }
	if ( $word =~ /http/ ) { return "false"; }
	else { return "true"; }
}

## Input: Text in the following format
## word_id|tag(gene, drug, AA, link)|annotation(text, html, xml)
## The function adds the line of tag to the tagged_words array
sub add_tagged_word
{
	print STDERR "word_search::word_index::add_tagged_word\tadded_tagged_word\t$_[0]\n";
	push @tagged_words, $_[0];
}

## This function returns the tagged words array
sub get_tagged_words
{
	return \@tagged_words;
}

## Input: word id
## The sub routine checks whether 
sub is_word_in_reference_section
{
	my $word_id = $_[0];
	## What is the line number for this word?
	my $line_number = id_to_line_number($word_id);
	## Is the previous line a reference line
	my $is_prev_ref = is_reference_line($document_lines{($line_number-1)});
	## If we are on the last line, then there is no next reference line to check.. therefore, we set
	## the is_next_ref to true, and will be invalidated in the following if clause
	my $is_next_ref = "true";
	## Is the next line a reference line?
	if (($line_number + 1) <= get_max_line){ $is_next_ref = is_reference_line($document_lines{($line_number+1)}); }
	## If the word is in a line sadnwiched by reference lines, that word will also belong to a 
	## reference line...
	if( $is_prev_ref eq "true" and $is_next_ref eq "true" ) { return "true"; }
	else { return "false"; }
}

# sub get_search_word
sub get_search_word
{
	my $word_id = $_[0];
	return $word_class_index{$word_id}->getRawWord();
}
return "true";