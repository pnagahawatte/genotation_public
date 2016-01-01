#!/usr/bin/env perl

package word_search::DocumentTaxonomy;
use warnings;
use strict;

## This module is a struct which holds information
## about all the taxonomies found in the document

sub new
{
	my $class = shift;
	my $self = { _major_taxonomy => shift,
				_taxonomies => shift }; 
	bless $self, $class;
	return $self;
}
