#!/usr/bin/env perl

package word_search::Drug;
use warnings;
use strict;

## This module is a struct which holds information
## about a gene annotation result returned from the
## database

sub new
{
	my $class = shift;
	my $self = { _drugname => shift,
				_accessionID => shift,
				_source => shift }; 
	bless $self, $class;
	return $self;
}

sub getDrugName
{
	my $self = $_[0];
	return $self->{_drugname};
}

sub getAccessionID
{
	my $self = $_[0];
	return $self->{_accessionID};
}

sub getSource
{
	my $self = $_[0];
	return $self->{_source};
}
return "true";