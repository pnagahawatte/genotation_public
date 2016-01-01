#!/usr/bin/env perl

## This script will parse an html file
## Input: html file
## QC: Checks whether the file has html tags
## Output: A set of text that the script has found to be
## the text of a document. This is without all the tags, and metadat
## that belongs to the html page

use warnings;
use strict;
use Getopt::Long;

## Command line arguments
my ($help, $file);
my @html_text;
my ($is_html, $in_body) = (0,0); ## All documents are assumed non-html until tags are found
my $body_text;
## Print usage information
if ( @ARGV < 1 or ! (GetOptions('help|?'=> \$help, 'file=s'=>\$file)) or defined $help )
{
	print "parse_html.pl [--file html file]\n";
	exit(-1);
}

## QC: Read the file into an array
## At the same time, check for html tags to make sure
## that the file is indeed an html file
open( FILE, "< $file" ) or die "Can't open the text file : $!";
while(<FILE>)
{
	## If html tags are present, set it as an html document
	if ($_ =~ /<html/ or $_ =~ /<.*\/html>/) { $is_html = 1; }
	push @html_text, $_;
}

## Proceed only if the document is identified as html
if ($is_html == 1)
{
	foreach(@html_text)
	{
		## We will only gather the text from the body portion of the 
		## document to annotate
		## Therefore, ignore the rest
		if($_ =~ /<body/){ $in_body = 1; }
		if($_ =~ /\/body>/){ $in_body = 0; }
		
		## Remove other tags in the body portion of the
		## document
		if( $in_body == 1)
		{
			##s/<[a-zA-Z\/][^>]*>//g
			$_ =~ s/<.*?>//g;
			#$_ =~ s/*//g;
			if ($_ =~ /\S*/) { print $_; }
		}
	}
}

else
{
	print STDERR "The document is not in html format\n";
	exit(-1);
}