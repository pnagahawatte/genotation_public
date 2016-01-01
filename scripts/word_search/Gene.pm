#!/usr/bin/env perl

package word_search::Gene;
use warnings;
use strict;

## This module is a struct which holds information
## about a gene annotation result returned from the
## database

sub new
{
	my $class = shift;
	my $self = { _symbol => shift,
				_taxonomy => shift,
				_gneomeID => shift,
				_common_name => shift,
				_species => shift,
				_display_symbol => shift}; 
	bless $self, $class;
	return $self;
}

sub getSymbol
{
	my $self = $_[0];
	return $self->{_symbol};
}

sub getTaxonomy
{
	my $self = $_[0];
	return $self->{_taxonomy};
}

sub getGneomeID
{
	my $self = $_[0];
	return $self->{_gneomeID};
}

sub getSpecies
{
	my $self = $_[0];
	return $self->{_species};
}

sub getCommonName
{
	my $self = $_[0];
	return $self->{_common_name};
}

sub setCommonName
{
	my $self = $_[0];
	my $commonName = $_[1];
	$self->{_common_name} = $commonName;
}

sub setSpecies
{
	my $self = $_[0];
	my $species = $_[1];
	$self->{_species} = $species;
}
return "true";