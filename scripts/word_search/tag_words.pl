#!/usr/bin/env perl

use warnings;
use strict;

use Getopt::Long;
#use DB_File;
use Benchmark;
## Set up the database handle using the
## db connect library
use SQL::CONN::db_connect;
#use gneome_db::GneomeHashDB;

my $start = new Benchmark;
#@ISA = ('Exporter');
#@EXPORT = ('db_connect');
use word_search::word_index qw(generate get_word_hash print_text get_search_words add_tagged_word 
	get_line print_word_index get_max_line set_doc_section get_doc_section get_test_all_words 
	get_included_section modify_text_annotation id_to_line_number print_doc_sections 
	get_tagged_words get_line_hash get_word_to_id_array id_to_line_characters set_word_hash);
use word_search::GeneWords;
use word_search::WordContext;
use annotation::GeneDBAnnotation;
#use gneome_db::common_words_db qw(add_word print_words word_exists);

## Fields of a document
## Each section that has been set to true will be excluded / filtered out
## from the document text
my ($abstract, $body, $references, $methods, $names, $in_reference_section, $annotate_pathway)
	= (0,0,0,0,0,0,0);
my $text;
my $add_to_buffer = 0;
my $filtered_sections = "";
my $LONGEST_WORD_THRESHOLD = 10;
my $ANNOTATION_TYPE = "text"; ## html, xml, json
## gene_words_to_annotate hash holds all the words that need to be annotated
## Key: word ( gene / drug etc)
## Value: List of word ids, where the word id refers to the id of the
## document's word_index hash
my %gene_words_to_annotate;

## Command line arguments
my $help;
## Print usage information
if ( @ARGV < 2 or ! (GetOptions('help|?'=> \$help, 'text=s'=>\$text)) or defined $help )
#if ( @ARGV < 2 or ! (GetOptions('help|?'=> \$help, 'names'=>\$names,
#		'references'=>\$references, 'text=s'=>\$text, "pathway"=>\$annotate_pathway)) or defined $help )
{
	print "find_gene_words.pl [--threshold Longest word threshold]\n";
	exit(-1);
}

## Generate the hash and set a pointer to the reference
my ($word_index) = generate($text);

## Generate the acronym hash
my $documentContext = word_search::DocumentContext->new($word_index, get_line_hash, get_word_to_id_array);
$documentContext->getAcronyms;

## Setup the annotation object
my $gene_annotation = annotation::GeneDBAnnotation->new();

## Object to perform the gene word search
my $geneWords = word_search::GeneWords->new($word_index, get_line_hash, get_word_to_id_array);
my $wordContext = word_search::WordContext->new($word_index);
#my ($common_words_db) = gneome_db::GneomeHashDB->getDB("common_words");
my $common_words = gneome_db::HashDB->new();
## String to hold common words in the format "(word),"
## That is whats used in inserting a string in sql
my %common_words_to_add;

## Parse the document to find which 
my ($search_words) = get_search_words();
## Flags to denote any identified words
my ($is_gene, $is_drug) = ("false" , "false");
#my ($search_words) = get_test_all_words();
foreach(keys %$search_words)
{
	my $search_word = $search_words->{$_};
	my $word_id = $_;
	my $term_found = "false";
	## HGNC gene naming criteria could be found here:
	## http://www.genenames.org/guidelines.html#criteria
	## Break apart word pairs such as BCR-ABL1
	## Label
print $search_word . "\n";
	GENE_CHECK:
	{
		if ($search_word =~ /(^[a-zA-Z].{1,10}[-\/][a-zA-Z].{1,10})/ ) 
		{ 
			## For each word, check if it is a gene
			my @fields = split /[-\/]/, $search_word;
			foreach(@fields) 
			{ 
				my $tag = $geneWords->tag($_, $word_id, $LONGEST_WORD_THRESHOLD);
				if ($tag eq "gene") 
				{ 
					add_tagged_word("$word_id|$_|$ANNOTATION_TYPE"); $term_found = "true";
					$gene_annotation->addWordToAnnotate($_, $word_id);
				} 
				elsif ($tag eq "drug") { $is_drug = "true"; $term_found = "true"; } 
				else 
				{
					## Make sure that a word that is a gene name or a drug name does not get 
					## inserted into the common_words table. To make sure we will check against
					## the gene list, drug list etc.
					add_common_word($_);
				} ## If the search word is not a gene nor a drug, add to common words list
				if( $term_found ne "true" )
				{
					print STDERR "word_search::tag_words\tdisregarded_word\t$search_word\t";
					print STDERR "first_word_not_a_gene\t$_\n";
					## Add the hyphenated - slash words to the common words list
					add_common_word($search_word);
					## Break out of the loop
					last GENE_CHECK;
				}
			}
		}
		## Non-paired words...
		else
		{
			my $tag = $geneWords->tag($search_word, $word_id, $LONGEST_WORD_THRESHOLD);
			if ($tag eq "gene") 
			{ 
				add_tagged_word("$word_id|$search_word|$ANNOTATION_TYPE"); 
				$gene_annotation->addWordToAnnotate($search_word, $word_id);
			} 
			elsif ($tag eq "drug") { $is_drug = "true"; }
			else { add_common_word($search_word); } ## If the search word is not a gene nor a drug, add to common words list
			## If the first word out of a few is not a gene, disregard the rest
		}
	}
	## End - GENE_CHECK
}

## Get the hash of Gene objects that are identified as genes
	my ($resultGenes) = $geneWords->getResultGenes();
	## Pass the hash reference to the GeneDBAnnotation module
	$gene_annotation->setAnnotatedGenes($resultGenes);
	my ($ann_words) = $gene_annotation->annotateGenes();
	
	#====================
	foreach (keys %$ann_words)
				{
					my $symbol = $ann_words->{$_}->getSymbol();
					my $species = $ann_words->{$_}->getGene()->getSpecies();
					## Symbol display
					print STDERR "Symbol: $symbol==$species\n";
					## Gene container
					
						## Collect the synonyms and print in an expandable div
							my ($synonyms) = $ann_words->{$_}->getAnnotations()->{synonyms};
							foreach (@$synonyms) { print STDERR "SYNONYM: $_\n"; }
						## Collect the pathways and print in an expandable div
							my ($pathways) = $ann_words->{$_}->getAnnotations()->{pathways};
							foreach (@$pathways) { print STDERR "pathway:$_\n"; }
						
						## Collect the diseases and print in an expandable div
#						print "<a href=\"#\" class=\"catSubmenu\" onclick=\"showHide(\'diseaseMenu$symbol_count\')\"><strong>Diseases</strong><div class=\"apex-dn\"></div></a>\n";
#						print qq(<div id="diseaseMenu$symbol_count" class="hide">\n);
							## Display the KEGG diseases
#							my ($keggDiseases) = $annotated_words->{$_}->getAnnotations()->{keggDiseases};						
#							foreach (@$keggDiseases) { 
#								my @fields = split ";", $_;
#								my $disease_name = $fields[0];
#								print "<a href=\"#\" class=\"detailSubmenu\" onclick=\"showHide(\'diseaseName$kegg_disease_count\')\"><strong>KEGG:$disease_name</strong><div class=\"apex-dn\"></div></a>\n";
#								print qq(<div id="diseaseName$kegg_disease_count" class="hide">\n);
#									print $htmlLinks->generateKeggDiseaseLine($_) ."\n";
#							}
							## Display the Medgen diseases
#							my ($medgenDiseases) = $annotated_words->{$_}->getAnnotations()->{medgenDiseases};
#							my @uniqueMedgenRecords = uniq (@$medgenDiseases);
#							foreach (@uniqueMedgenRecords) { 
#								my @fields = split ";", $_;
#								my $disease_name = $fields[0];
#								print $htmlLinks->generateMedgenDiseaseLine($_);
#								print qq(<div class="annotationSeperator"></div>\n);
#								$kegg_disease_count++;
							}
#=================================
	
#$gene_annotation->annotateGenes();
#$gene_annotation->printPathways();
## Insert all the common words to the common_words table in the database
my $common_word_list;
foreach (keys %common_words_to_add ) { $common_word_list .= "('$_'),"; }
#$common_words->add_common_word($common_word_list);

## Contains the checks and insertion of a 
## word into the common words table
sub add_common_word
{
	my $word = $_[0];
	$word =~ s/\s*//g;
	## If there are "'" characters, only one character letters dismiss the word
	if ( $word =~ /\'/ || $word =~ /[^A-Za-z]/ || length $word == 1 ) { return; }
	## Only add words starting with a letter
	if ( ($geneWords->isNotCommonWord($word) eq "false") && ($word =~ /^[A-Za-z]/ ) ) 
		## Add to the common words hash
		{ $common_words_to_add{ $word } = $word; }

}

my $end = new Benchmark;
my $diff = timediff($end, $start);
print STDERR "Time taken was ", timestr($diff, 'all'), " seconds\n";
