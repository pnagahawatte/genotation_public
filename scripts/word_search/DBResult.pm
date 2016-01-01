#!/usr/bin/env perl

package word_search::DBResult;
use warnings;
use strict;

## This module is a struct which holds information
## about a gene annotation result returned from the
## database

sub new
{
	my $class = shift;
	my $resultType = shift;
	my $term = shift;
	my $gneomeIDs = shift; ## Comma separated list of genomeIDs
	my $self= { _result_type => $resultType,
				_ids => $gneomeIDs,
				_term => $term}; 
	bless $self, $class;
	return $self;
}

sub getResultType
{
	my $self = $_[0];
	return $self->{_result_type};
}

sub getTerm
{
	my $self = $_[0];
	return $self->{_term};
}

sub getIDs
{
	my $self = $_[0];
	my $ids = $self->{_ids};
	if (defined $ids) { $ids =~ s/\|/,/; }
	return $ids;
}
return "true";