#!/usr/bin/perl -w

use lib "/var/www/Genotation/scripts";

use CGI;
use warnings;
use strict;
use gui::html::parsers::parse_pdf;
use gui::html::parsers::parse_html;
use gui::html::HtmlLinks;
use word_search::TagWords;
use List::MoreUtils 'uniq';
use LWP::UserAgent;
use JSON::Parse ':all';
use HTML::Parser;
use XML::Simple;
use Data::Dumper;
use HTTP::Request;
use IO::File qw();
use File::Copy;
use File::Slurp;

my $q = CGI->new();
my $gene_list = $q->param('gene_list');
print "Content-Type: text/html\n\n";
my $FILE_CREATION_DIR = "/var/www/Genotation/temp/";

my @fields = split ",", $gene_list;
my $json_file= $FILE_CREATION_DIR . time() . ".txt";
open(my $fh, "> $json_file") or die "Can't open the text file $json_file: $!";

foreach my $gene (@fields)
{
	print $fh "$gene\n"; 
}
close($fh);

open(my $html1, "< /var/www/Genotation/temp/doctogo_part1.html") or die "Can't open the text file /var/www/Genotation/temp/doctogo_part1.html: $!";
while(<$html1>)
{
	print $_;
}
close($html1);

my $tagWords = word_search::TagWords->new($json_file);
		my ($returnObject) = $tagWords->getAnnotations();
		
		my ($annotated_words) = $returnObject->{"genes"};
		## Sort the annotated words
			
		my ($annotated_drug_words) = $returnObject->{"drugs"};
		foreach (keys %$annotated_drug_words){	print STDERR "DRUG: " . $annotated_drug_words->{$_}->getDrugName() . "\n"; }

		my $htmlLinks = gui::html::HtmlLinks->new();
		my $kegg_disease_count = 0;
		my ($count, $symbolCount) = (1,0);
		print "\t{\n";
			print qq(\t"name": "User query",\n);
			print qq(\t"children": [\n);

			
			## Sort the keys by the gene symbold of the returned results
			my @sorted_keys = sort { lc $annotated_words->{$a}->getGene()->getSymbol() cmp lc $annotated_words->{$b}->getGene()->getSymbol() } keys %$annotated_words;
			## What is the last key of the annotated_words hash
			my $annotated_words_last_key = $sorted_keys[$#sorted_keys];
			foreach my $hashKey(@sorted_keys)
			{
				#if( $organism eq ($annotated_words->{$hashKey}->getGene()->getSpecies()))
				#{
					my $currentSpecies = $annotated_words->{$hashKey}->getGene()->getSpecies();
					my $symbol = $annotated_words->{$hashKey}->getGene()->getSymbol();

					## Header for the JSON data...
					print "\t{\n";
					print qq(\t\t"name": "$symbol",\n);
					print qq(\t\t"children": [\n);
					my $json_body;
						my ($synonyms) = $annotated_words->{$hashKey}->getAnnotations()->{"synonyms"};
						if (@$synonyms)
						{
							## JSON synonym data - start
							my $json_doctogo_synonym;
							$json_doctogo_synonym .= qq(\t\t\t{\n);
							$json_doctogo_synonym .= qq(\t\t\t\t"name": "Synonyms",\n);
							$json_doctogo_synonym .= qq(\t\t\t\t"children": [\n);
							foreach (@$synonyms) 
							{ 
								## JSON synonym data -- detail
								$json_doctogo_synonym .= qq(\t\t\t\t\t{"name": "$_"},\n);
							}
							## Remove the last comma of the string
							$json_doctogo_synonym =~ s/,$//;
							#$json_doctogo_synonym .= $json_doctogo_synonym;
							$json_doctogo_synonym .= "\t\t\t\t]\n";
							$json_doctogo_synonym .= "\t\t\t},\n";
							## Add synonyms to JSON body
							$json_body = $json_doctogo_synonym;
						}
						## End printing synonyms

						## Print the variants, only if variants were found..
						my ($variants) = $annotated_words->{$hashKey}->getAnnotations()->{"cvVariants"};
						if(@$variants)
						{
							## JSON variant data -- start
							my $json_doctogo_variant;
							$json_doctogo_variant .= qq(\t\t\t{\n);
							$json_doctogo_variant .= qq(\t\t\t\t"name": "Variants",\n);
							$json_doctogo_variant .= qq(\t\t\t\t"children": [\n);
							foreach my $variant (@$variants) { 
								## JSON variant data detail
								$json_doctogo_variant .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generateVariantrsID($variant) . "\",\"link\": \"" . $htmlLinks->generateVariantLink($variant) . "\"},\n";
							}
							## Remove the last comma of the string
							$json_doctogo_variant =~ s/,$//;
							$json_doctogo_variant .= "\t\t\t\t]\n";
							$json_doctogo_variant .= "\t\t\t},\n";
							## Add synonyms to JSON body
							$json_body .= $json_doctogo_variant;
						}
						
						## End printing variants
						
						## Start printing uniprot entries
						## Print uniprot proteins, only if proteins are available..
						my ($uniprotEntries) = $annotated_words->{$hashKey}->getAnnotations()->{"uniprotEntries"};
						if(@$uniprotEntries)
						{
							## JSON variant data -- start
							my $json_doctogo_uniprot;
							$json_doctogo_uniprot .= qq(\t\t\t{\n);
							$json_doctogo_uniprot .= qq(\t\t\t\t"name": "Protein products",\n);
							$json_doctogo_uniprot .= qq(\t\t\t\t"children": [\n);
							foreach my $protein (@$uniprotEntries) { 
								## JSON variant data detail
								$json_doctogo_uniprot .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generateUniprotDescription($protein) . "\",\"link\": \"" . $htmlLinks->generateUniprotLink($protein) . "\"},\n";
							}
							## Remove the last comma of the string
							$json_doctogo_uniprot =~ s/,$//;
							$json_doctogo_uniprot .= "\t\t\t\t]\n";
							$json_doctogo_uniprot .= "\t\t\t},\n";
							## Add synonyms to JSON body
							$json_body .= $json_doctogo_uniprot;
						}
						
						
						## Start printing uniprot entries
						## Print uniprot proteins, only if proteins are available..
						my ($pharmGKBDrugs) = $annotated_words->{$hashKey}->getAnnotations()->{"pharmGKBRelationships"};
						if(@$pharmGKBDrugs)
						{
							## JSON variant data -- start
							my $json_doctogo_pharmgkb_drugs;
							$json_doctogo_pharmgkb_drugs .= qq(\t\t\t{\n);
							$json_doctogo_pharmgkb_drugs .= qq(\t\t\t\t"name": "PharmGKB Drugs",\n);
							$json_doctogo_pharmgkb_drugs .= qq(\t\t\t\t"children": [\n);
							foreach my $drug (@$pharmGKBDrugs) { 
								## JSON variant data detail
								$json_doctogo_pharmgkb_drugs .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generatePharmGKBDescription($drug) . "\",\"link\": \"" . $htmlLinks->generatePharmGKBLink($drug) . "\"},\n";
							}
							## Remove the last comma of the string
							$json_doctogo_pharmgkb_drugs =~ s/,$//;
							$json_doctogo_pharmgkb_drugs .= "\t\t\t\t]\n";
							$json_doctogo_pharmgkb_drugs .= "\t\t\t},\n";
							## Add synonyms to JSON body
							$json_body .= $json_doctogo_pharmgkb_drugs;
						}
										
						## Collect the pathways and print in an expandable div
						my ($pathways) = $annotated_words->{$hashKey}->getAnnotations()->{"pathways"};
						if (@$pathways)
						{
							## JSON pathway data -- start
							my $json_doctogo_pathways;
							$json_doctogo_pathways .= qq(\t\t\t{\n);
							$json_doctogo_pathways .= qq(\t\t\t\t"name": "Pathways",\n);
							$json_doctogo_pathways .= qq(\t\t\t\t"children": [\n);
							foreach my $pw (@$pathways) { 
								## JSON pathway data -- detail
								$json_doctogo_pathways .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generatePathwayDescription($pw) . "\",\"link\": \"" . $htmlLinks->generatePathwayLink($pw) . "\"},\n";
							}
							## Remove the last comma of the string
							$json_doctogo_pathways =~ s/,$//;
							$json_doctogo_pathways .= "\t\t\t\t]\n";
							$json_doctogo_pathways .= "\t\t\t},\n";
							## Add synonyms to JSON body
							$json_body .= $json_doctogo_pathways;
						}
						## End printing pathways
						
						## Collect the diseases and print in an expandable div
						my ($keggDiseases) = $annotated_words->{$hashKey}->getAnnotations()->{"keggDiseases"};						
						my ($medgenDiseases) = $annotated_words->{$hashKey}->getAnnotations()->{"medgenDiseases"};
						if(@$keggDiseases || @$medgenDiseases)
						{
							## If found, display the KEGG diseases
							if(@$keggDiseases)
							{
								## JSON KEGG disease start
								my $json_doctogo_keggDiseases;
								$json_doctogo_keggDiseases .= qq(\t\t\t{\n);
								$json_doctogo_keggDiseases .= qq(\t\t\t\t"name": "Kegg-Diseases",\n);
								$json_doctogo_keggDiseases .= qq(\t\t\t\t"children": [\n);
								foreach my $kd (@$keggDiseases) { 
									my @fields = split ";", $kd;
									my $disease_name = $fields[0];
									$kegg_disease_count++;
									## JSON KEGG disease -- detail
									$json_doctogo_keggDiseases .= "\t\t\t\t\t{\t\"name\": \"" . $disease_name . "\",\"link\": \"" . $htmlLinks->generateKeggDiseaseLink($kd) . "\"},\n";
								}
								## Remove the last comma of the string
								$json_doctogo_keggDiseases =~ s/,$//;
								$json_doctogo_keggDiseases .= "\t\t\t\t]\n";
								$json_doctogo_keggDiseases .= "\t\t\t},\n";
								## Add synonyms to JSON body
								$json_body .= $json_doctogo_keggDiseases;
							}
							
							## Display the Medgen diseases
							if(@$medgenDiseases)
							{
								## JSON medgen disease -- start
								my $json_doctogo_medgenDiseases;
								$json_doctogo_medgenDiseases .= qq(\t\t\t{\n);
								$json_doctogo_medgenDiseases .= qq(\t\t\t\t"name": "Medgen",\n);
								$json_doctogo_medgenDiseases .= qq(\t\t\t\t"children": [\n);
								my @uniqueMedgenRecords = uniq (@$medgenDiseases);
								foreach (@uniqueMedgenRecords) { 
									my @fields = split ";", $_;
									my $disease_name = $fields[1];
									$kegg_disease_count++;
									## JSON medgen disease -- detail
									$json_doctogo_medgenDiseases .= "\t\t\t\t\t{\t\"name\": \"" . $disease_name . "\",\"link\": \"" . $htmlLinks->generateMedgenDiseaseLink($_) . "\"},\n";
								}
								## Remove the last comma of the string
								$json_doctogo_medgenDiseases =~ s/,$//;
								$json_doctogo_medgenDiseases .= "\t\t\t\t]\n";
								$json_doctogo_medgenDiseases .= "\t\t\t},\n";
								## Add synonyms to JSON body
								$json_body .= $json_doctogo_medgenDiseases;
							}
						}
					$symbolCount++;
					$json_body =~ s/,$//;
					print $json_body;

					print "\t\t]\n";
					## If last element, just print the "}"
					if ($hashKey == $annotated_words_last_key ) { print "\t}\n"; }
					else { print "\t},\n"; }


				#}
			}
		#}
		print "\t]\n";
		print "}\n";
open(my $html2, "< /var/www/Genotation/temp/doctogo_part2.html") or die "Can't open the text file /var/www/Genotation/temp/doctogo_part2.html: $!";
while(<$html2>)
{
	print $_;
}
close($html2);