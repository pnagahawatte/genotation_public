#!/usr/bin/env perl

#################################################
# Script to QC accession number file used in postprocess
# needs two inputs - the file to be tested and a genbank file
# will output a file of discrepancies to be checked by a human
# uses a modified genbank parser, which has already been modified from the original for protein painter
#################################################

# vim: tw=78: sw=4: ts=4: et: 

# $Id: genbank-parser.pl 9 2008-01-28 20:08:45Z kyclark $

#use strict;
#use warnings;
use POSIX qw(ceil);
use English qw( -no_match_vars );
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use Readonly;
use Data::Dumper;
use DBI;
use Storable;
use List::Util 'max';
use Getopt::Long;

my $optionOK = GetOptions(
	'g|genbank=s'		=> \@files,
	'c|check=s'		=> \$input,
	'o|output=s'		=> \$output
);


use lib '/sonas/hpcf/migrate_apps/apps/gnu-apps/NextGen/mpbin/perl_modules'; 
use GenBankParser;

Readonly my $VERSION => qq$Revision: 9 $ =~ /(\d+)/;


my ( $help, $man_page, $show_version );
GetOptions(
'help'    => \$help,
'man'     => \$man_page,
'version' => \$show_version,
) or pod2usage(2);

if ( $help || $man_page ) {
pod2usage({
	-exitval => 0,
	-verbose => $man_page ? 2 : 1
});
}; 

if ( $show_version ) {
my $prog = basename( $PROGRAM_NAME );
print "$prog v$VERSION\n";
exit 0;
}
my %FEATURES;
my $details;
my %feature;
my @FEATURES;
my @accession;
my $a;
my $b;
my $FEATURES;
my $feature;
my $location;
my $name;
my @files  = @ARGV or pod2usage('No input files');
my $parser = Bio::GenBankParser->new;


##############################
######### File to check
##############################

#my $input = 'gene_transcript_matrix.withNM';

my %check;

#####################################################################################
######## This part loads or parses genbank - stores as a hash for easier re-running
#####################################################################################

my %genbank;
$count=0;
for my $file ( @files ) 
{

	$parser->file( $file );
#print $parser->grammar;

#	my $pubmed_ids;
	
	while ( my $seq = $parser->next_seq ) 
	{
		my $locus_name = $seq->{'LOCUS'}{'locus_name'};
		my $gi = $seq->{'VERSION'};
		@gi = @{$gi}; 
		my $gi_for_output = $gi[1];
		my $size = $seq->{'LOCUS'}{'sequence_length'};
		$size =~ s/ bp//g;
		if($locus_name !~ m/NM/)
		{
			next;
		}
		my $definition = $seq->{'DEFINITION'};
		my @features = $seq->{'FEATURES'};
		my $title = $seq->{'TITLE'};
		my @reference = $seq->{'REFERENCES'};
		@tmp = @{$features[0]};
		
		
		foreach(@features)
		{
			foreach(@{$_})
			{
				%hash = %{$_};
				for my $key (keys %hash)
				{
				for my $key2 (keys %{$hash{$key}})
					{
						if ($key2 eq "note")
						{
							$note =  $hash{$key}{$key2};
						}
						if ($key2 eq "gene")
						{
							$gene =  $hash{$key}{$key2};
						}
						if ($key2 eq "gene_synonym")
						{
							$gene_synonym =  $hash{$key}{$key2};
						}
					}
				}
			}
		
		}
#print scalar(@reference);

		foreach(@reference)
		{
		
			foreach(@{$_})
			{
				%hash = %{$_};
				for my $key (keys %hash)
				{
					print "Key: " . $key . "\n";
					#if ($key eq "PUBMED")
					#{

						print $hash{$key} . "\n";
					#	$pubmed_ids .=  $hash{$key} . ",";
					#}
				}
			}
		
		}
		## Print out the summary for the gene
		my $comments = $seq->{'COMMENT'};
		my @paragraphs = split("\n ", $comments);
		my $print = "false";
		my $description;
		foreach (@paragraphs)
		{
			## Only the paragraph that starts with SUmmary: contains
			## the text needed in this section
			## Start printing the description of gene
			if($_ =~ m/^\s*Summary:/){
				$print  = "true";
				$_ =~ s/^\s*Summary://;
				chomp($_);
			}
			if($_ =~ m/^\s*$/){
				$print = "false";
			}
			if($_ =~ m/^COMPLETENESS:/){
				$print = "false";
			}
			
			if($print eq "true")
			{
				$_ =~ s/^\s*//;
				chomp($_);
				$description .= $_ . " ";
			}
			else
			{
				$description = "NA";
			}
		}
		my $print_ids = substr  $pubmed_ids, 0, -1;
#		print $locus_name . "\t" . $definition . "\t" . $gene . "\t" . $description . "\t" . $print_ids . "\n";
	}
}

=pod

=head1 NAME

genbank-parser.pl - parse GenBank records into YAML

=head1 VERSION

This documentation refers to version $Revision: 9 $

=head1 SYNOPSIS

  genbank-parser.pl file1.seq [file2.seq ...]

Options:

  --help        Show brief help and exit
  --man         Show full documentation
  --version     Show version and exit

=head1 DESCRIPTION

This is little more than an example showing a trivial use of 
Bio::GenBankParser.  Here we convert a stream of files into YAML
on STDOUT.

=head1 SEE ALSO

Bio::GenBankParser, YAML.

=head1 AUTHOR

Ken Youens-Clark E<lt>kclark@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2008 Cold Spring Harbor Laboratory

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
