#!/usr/bin/env perl

package word_search::Uniprot;
use warnings;
use strict;

## This module is a struct which holds information
## about a gene annotation result returned from the
## database

sub new
{
	my $class = shift;
	my $self = { _uniprot_entry => shift,
				_uniprot_description => shift }; 
	bless $self, $class;
	return $self;
}

sub getUniprotEntry
{
	my $self = $_[0];
	return $self->{_uniprot_entry};
}

sub getUniprotDescription
{
	my $self = $_[0];
	return $self->{_uniprot_description};
}

return "true";
