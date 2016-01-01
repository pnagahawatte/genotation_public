#!/usr/bin/perl -w

use CGI ':standard';
## This script inspects the input and redirects to the
## appropriate page

#print "Content-Type: text/html\n\n";
## Refactor: we may need to use this script for other pages as well..
## Therefore identify the calling page
my $q = CGI->new();
## REFACTOR: To identify more document types
my $terms = $q->param('terms');

## Is this a url or a set of search terms?
## These are search terms, there for submit terms to search page
if ($terms =~ /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*/)
	{ print "Location: DisplayAnnotation.pl?linkurl=$terms\n\n"; }
## Refactor - differentiate between pdf and html and redirect appropriately
else
	{ print "Location: search.pl?terms=$terms\n\n"; }
