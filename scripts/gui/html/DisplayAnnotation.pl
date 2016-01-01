#!/usr/bin/perl -w

use lib "/var/www/Genotation/scripts";

use CGI;
use warnings;
#use strict;
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

## The file upload directory is set to the global variable
## here to refrain from storing it in the index.html file
my $FILE_UPLOAD_ALIAS = "docs/"; ## This is an alias pointing to: /var/www/Genotation/temp/
#my $FILE_UPLOAD_DIR = "";
my $FILE_UPLOAD_DIR = "/var/www/Genotation/temp/";
print "Content-Type: text/html\n\n";

## Doc2go document information
my $doctogo_document = "doc2go" . time() . ".d2g";
## Copy the html part 1 file to directory
copy("/var/www/Genotation/temp/doctogo_part1.html", "$FILE_UPLOAD_DIR/$doctogo_document") or die "Copy failed: $!";
## Open the JSN file to be written
my $json_doctogo_file = "$FILE_UPLOAD_DIR/$doctogo_document";

my $q = CGI->new();
## REFACTOR: To identify more document types
my $pmcurl = $q->param('pmcurl');
my $linkurl = $q->param('linkurl');
my $fileurl = $q->param('fileurl');
my $pdfDocument; ## Holds the Apache resolved link to file
my $pdfFile; ## Holds the path to the actual pdf file
my $htmlDocument; ## Holds the url to the actual html file
my $documentType;
my $txt_filename;
## Get the link to the pdf using the pmc link
if ( defined $pmcurl)
{
	my $httpRequest = HTTP::Request->new(GET => $pmcurl);
	my $ua = LWP::UserAgent->new;
		$ua->timeout(10);
	my $linkResponse = $ua->request($httpRequest);
	if ($linkResponse->is_success)
	{
		my $xmlContent = $linkResponse->content;
		my $parser = new XML::Simple;
		my $data = $parser->XMLin($xmlContent);
		my $links = $data->{"records"}->{"record"}->{link};
		my $pdfFound = "false";
		foreach(@$links)
		{
			my $fileLink = $_->{"href"};
			## Found a pdf
			if ($fileLink =~ /\.pdf$/ ) 
			{
				$pdfFound = "true";
				$pdfFile = $pdfDocument = $fileLink;
				$documentType = "pdf";
			}
		}
		## Did not find a pdf, therefore cannot proceed.
		## Print error and stop
		if ( $pdfFound eq "false" )
		{
			print STDERR "gui::html::DisplayAnnotation.pl- could not find pdf $pmcurl\n";
			print "<pre><strong>PMC did not have a pdf file for this article. Please use back button and select another</strong></pre>";
			exit -1;
		}
	}
	else
	{
		print STDERR "gui::html::DisplayAnnotation.pl- no response from PMC server fetching pdf: $pmcurl\n";
		print "<pre><strong>PMC did not have a pdf file for $pmcurl : Please use back button and select another</strong></pre>";
		exit -1;
	}
}
## Linkurl could be either html or pdf
elsif (defined $linkurl) 
{ 
	if ( $linkurl =~ /\.pdf(^A-Za-z){0,2}$/i ) { $pdfDocument = $linkurl; $documentType = "pdf";}
	#if ( $linkurl =~ /\.html?(^A-Za-z){0,2}$/i ) { $htmlDocument = $linkurl; $documentType = "html";}
	else { $htmlDocument = $linkurl; $documentType = "html";}
}

elsif (defined $fileurl) { $pdfDocument = $FILE_UPLOAD_ALIAS . $fileurl; $documentType = "pdf";
							$pdfFile = $FILE_UPLOAD_DIR . $fileurl;}

## Get the pdf directly, if the user has provided a 
## Counters used in identifying div's
my $kegg_disease_count = 0;

print "<!DOCTYPE html>";
print "<html>";
	## Start -- Head
	print "<head>";
		print "<title>Genotation - annotated manuscript</title>";
		# print qq(<link rel="stylesheet" type="text/css" href="res/style.css">);
		# print qq(<link rel="stylesheet" type="text/css" href="res/menuStyle.css">);
		print qq(<link rel="icon" href="res/favicon.ico" type="image/x-icon"/>);
		print qq(<link rel="shortcut icon" href="res/favicon.ico" type="image/x-icon"/>);
		# print qq(<script type="text/javascript" src="JS/pdfobject.js"></script>);
		# print qq(<script type="text/javascript" src="JS/main.js"></script>);
		# print qq(<link href="http://fonts.googleapis.com/css?family=Vollkorn" rel="stylesheet" type="text/css">);
		# print qq(<script src="JS/main.js"></script>);
		print qq(<link rel="stylesheet" type="text/css" href="stylesheets/styles.css">);
		print qq(<script type="text/javascript" src="https://www.dropbox.com/static/api/2/dropins.js" id="dropboxjs" data-app-key="hrkqepa6e2do93s"></script>);
	print "</head>";
	## End -- Head
	
	## Start -- Body
	print "<body class=\"annotation-body\">";
		## Start -- main menu
		## REFACTOR: THIS IS WHERE WE WILL CHECK FOR THE DOCUMENT TYPE
		
		## Start the progress bar
		if($documentType eq "pdf")
		{
			my $pdf = gui::html::parsers::parse_pdf->new("$pdfFile");
			$txt_filename = $pdf->getPdfText();
		}
		elsif($documentType eq "html")
		{
			my $html = gui::html::parsers::parse_html->new("$htmlDocument");
			$txt_filename = $html->getHtmlText();
		}
		else
		{
			##Refactor: redirect to a pre-defined error page
			print STDERR "gui::html::DisplayAnnotation.pl - file type mismatch\n";
			exit -1;
		}
		my $tagWords = word_search::TagWords->new($txt_filename);
		
		
		my ($returnObject) = $tagWords->getAnnotations();
		
		my ($annotated_words) = $returnObject->{"genes"};
		## Sort the annotated words
			
		my ($annotated_drug_words) = $returnObject->{"drugs"};
		foreach (keys %$annotated_drug_words){	print STDERR "DRUG: " . $annotated_drug_words->{$_}->getDrugName() . "\n"; } 
		## Done with the text file.. delete it
#		unlink "$txt_filename";

		print qq(<nav class="navbar navbar-inverse">);
			print qq(<div class="navbar-header">);
				print qq(<a class="navbar-brand" href="/">Genotation</a>);
			print qq(</div>); # End .navbar-header

			print qq(<ul class="nav navbar-nav navbar-right">);
#				print qq(<li><a href="docs/) . $json_doctogo_file . qq(" download="gnotation_doctogo.d2g"><button type="button" class="navbar-toggle save-btn"><span class="glyphicon glyphicon-floppy-disk" aria-hidden="true"></span></button></a></li>);
				print qq(<li><a href="docs/) . $doctogo_document . qq(" download="gnotation_doctogo.d2g"><button type="button" class="navbar-toggle save-btn"><span class="glyphicon glyphicon-floppy-disk" aria-hidden="true"></span></button></a></li>);
				print qq(<li><button type="button" class="navbar-toggle" data-toggle="offcanvas" data-autohide="false" data-target="#annotations-nav" data-canvas="#documentContainer">Annotations</button></li>);
				print qq(<li><a href="help.html"><button type="button" class="navbar-toggle help-btn"><span class="glyphicon glyphicon-question-sign"></span></button></a></li>);
			print qq(</ul>);
		print qq(</nav>); # end .navbar.navbar-inverse

		
		# print qq(<div id="menuContainer">\n);
		# 	print qq(<a href="#" onclick="toggle_visibility('detailsContainer');"><div id="lines" class="btn"></div></a>\n);
		# 	print qq(<a href="index.html" class="homeAnchor">Genotation</a>\n);
		# print "</div>\n";
		## End -- main menu
		
		## Start -- Document display
		print qq(<div class="container-fluid no-padding document-wrapper">);
		print qq(<div id="documentContainer" class="documentContainer">);
			## Show the pdf document in the document container
			# if($documentType eq "pdf") { print "<script>loadPDF(\"$pdfDocument\");</script>\n"; }
			## Show the html page in an iFrame
			if($documentType eq "html") { print qq(<iframe src="$htmlDocument" sandbox="allow-forms allow-scripts" class="docFrame"></iframe>); }		
		print qq(</div>);
		print qq(</div>);
		## End -- Document display
	
		## Start -- annotation section
		print qq(<nav id="annotations-nav" class="navmenu navmenu-default navmenu-fixed-right offcanvas" role="navigation">);
		
		## 
		print qq(<ul class="nav nav-tabs" role="tablist">);
		
		my %organisms;
		
		my ($organismDivArray, $species);
		foreach (keys %$annotated_words)
		{
			$species = $annotated_words->{$_}->getGene()->getSpecies();
			$organisms{$species} = "$species_tab";
		}
		
		## 
		foreach( keys %organisms){ $organismDivArray .= "'geneDetailContainer" . $_ . "',";	}
		if ( keys %$annotated_drug_words > 0 ) { $organismDivArray .= "'geneDetailContainerDrugs',";}
		$organismDivArray =~ s/,$//;
		
		## Print the header tabs for species and drugs
		my $active = 1;
		foreach( keys %organisms){ 
			my $activeClass = $active ? "active" : "";
			my $tabName = $_ eq "" ? 'Genes' : $_;
			print qq(<li role="presentation" class="$activeClass"><a href="#geneDetailContainerTab$_" aria-controls="geneDetailContainer$_" role="tab" data-toggle="tab">$tabName</a></li>);	
			$active = 0;
		}
		if ( keys %$annotated_drug_words > 0 ) { 
			my $activeClass = $active ? "active" : "";
			print qq(<li role="presentation" class="$activeClass"><a href="#geneDetailContainerDrugs" aria-controls="geneDetailContainerDrugs" role="tab" data-toggle="tab">Drugs</a></li>);	
			$active = 0;
		}
		
		print qq(</ul>); # End ul.nav.nav-tabs
		
		my ($count, $symbolCount) = (1,0);
		## htmlLinks object that generates specific html code
		my $htmlLinks = gui::html::HtmlLinks->new();
		
		## Print the detail DIVs
		$active = 1;
		print qq(<div class="tab-content">);
		foreach my $organism ( keys %organisms)
		{
			my $activeClass = $active ? "in active" : "";
			print qq(<div id="geneDetailContainerTab$organism" role="tabpanel" class="tab-panel fade $activeClass">);
			$active = 0;

					# Put our search bar as our first item
			print qq(<div class="input-group">);
				print qq(<input type="text" id="search$organism" name="search$organism" class="form-control search" placeholder="Search" value="" />);
				print qq(<div class="input-group-btn">);
					print qq(<button class="btn btn-default search$organism-btn" data-sort="name" type="button"><span class="glyphicon glyphicon-search"></span></button>);
				print qq(</div>);
			print qq(</div>);
			
			
			## Show information about the first organism
			if($count == 1)
			{
				print qq(<ul id="geneDetailContainer$organism" class="nav primary-nav navmenu-nav list">);
				$count++;
			}
			else
			{
				print qq(<ul id="geneDetailContainer$organism" class="nav primary-nav navmenu-nav list">);
			}

			## Start writing to the doctogo file
			open(JSON_DOCTOGO_FILE, ">> $json_doctogo_file" ) or die "Can't open the text file $json_doctogo_file: $!";
			print JSON_DOCTOGO_FILE "{\n";
			print JSON_DOCTOGO_FILE qq(\t"name": "Document",\n);
			print JSON_DOCTOGO_FILE qq(\t"children": [\n);

			
			## Sort the keys by the gene symbold of the returned results
			my @sorted_keys = sort { lc $annotated_words->{$a}->getGene()->getSymbol() cmp lc $annotated_words->{$b}->getGene()->getSymbol() } keys %$annotated_words;
			## What is the last key of the annotated_words hash
			my $annotated_words_last_key = $sorted_keys[$#sorted_keys];
			foreach my $hashKey(@sorted_keys)
			{
				if( $organism eq ($annotated_words->{$hashKey}->getGene()->getSpecies()))
				{
					my $currentSpecies = $annotated_words->{$hashKey}->getGene()->getSpecies();
					my $symbol = $annotated_words->{$hashKey}->getGene()->getSymbol();
					print qq(<li>);
					# print $htmlLinks->generateSymbolHeaderLine($symbol, $currentSpecies, $symbolCount);

					## Header for the JSON data...
					print JSON_DOCTOGO_FILE "\t{\n";
					print JSON_DOCTOGO_FILE qq(\t\t"name": "$symbol",\n);
					print JSON_DOCTOGO_FILE qq(\t\t"children": [\n);
					my $json_body;
					print qq(<a href="#symbolMenu$symbolCount" class="accordian-toggle name" data-toggle="collapse" data-parent="geneDetailContainer$organism">$symbol($currentSpecies) <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
					## div to hold all the annotations for a symbol
					print qq(<ul id="symbolMenu$symbolCount" class="nav secondary-nav collapse">);
						##Print the synonyms, only if synonyms were found for a gene symbol
						my ($synonyms) = $annotated_words->{$hashKey}->getAnnotations()->{"synonyms"};
						if (@$synonyms)
						{
							## JSON synonym data - start
							my $json_doctogo_synonym;
							$json_doctogo_synonym .= qq(\t\t\t{\n);
							$json_doctogo_synonym .= qq(\t\t\t\t"name": "Synonyms",\n);
							$json_doctogo_synonym .= qq(\t\t\t\t"children": [\n);
							print qq(<li>);
							print qq(<a href="#synonymMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">Synonyms <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
							print qq(<ul id="synonymMenu$symbolCount" class="nav tertiary-nav collapse">);
							foreach (@$synonyms) 
							{ 
								print qq(<li><a href="#">$_</a></li>);
								## JSON synonym data -- detail
								$json_doctogo_synonym .= qq(\t\t\t\t\t{"name": "$_"},\n);
							}
							print qq(</ul>);
							print qq(</li>);
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
							print qq(<li>);
							print qq(<a href="#variantMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">Variants <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
							print qq(<ul id="variantMenu$symbolCount" class="nav tertiary-nav collapse">);
							foreach my $variant (@$variants) { 
								## JSON variant data detail
								$json_doctogo_variant .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generateVariantrsID($variant) . "\",\"link\": \"" . $htmlLinks->generateVariantLink($variant) . "\"},\n";
								print qq(<li>);
								print $htmlLinks->generateVariantLine($variant);
								print qq(</li>);
							}
							print qq(</ul>);
							print qq(</li>);
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
						print STDERR "uniprot $_\n";
							## JSON variant data -- start
							my $json_doctogo_uniprot;
							$json_doctogo_uniprot .= qq(\t\t\t{\n);
							$json_doctogo_uniprot .= qq(\t\t\t\t"name": "Protein products",\n);
							$json_doctogo_uniprot .= qq(\t\t\t\t"children": [\n);
							print qq(<li>);
							print qq(<a href="#uniprotMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">Protein Product <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
							print qq(<ul id="uniprotMenu$symbolCount" class="nav tertiary-nav collapse">);
							foreach my $protein (@$uniprotEntries) { 
								## JSON variant data detail
								$json_doctogo_uniprot .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generateUniprotDescription($protein) . "\",\"link\": \"" . $htmlLinks->generateUniprotLink($protein) . "\"},\n";
								print qq(<li>);
								print $htmlLinks->generateUniprotLine($protein);
								print qq(</li>);
							}
							print qq(</ul>);
							print qq(</li>);
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
	print qq(<li>);
	print qq(<a href="#drugMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">PharmGKB Drugs<span class="glyphicon glyphicon-triangle-bottom"></span></a>);
	print qq(<ul id="drugMenu$symbolCount" class="nav tertiary-nav collapse">);
	foreach my $drug (@$pharmGKBDrugs) { 
		## JSON variant data detail
		$json_doctogo_pharmgkb_drugs .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generatePharmGKBDescription($drug) . "\",\"link\": \"" . $htmlLinks->generatePharmGKBLink($drug) . "\"},\n";
		print qq(<li>);
		print $htmlLinks->generatePharmGKBLine($drug);
		print qq(</li>);
	}
	print qq(</ul>);
	print qq(</li>);
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
							print qq(<li>);
							print qq(<a href="#pathwayMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">Pathways <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
							print qq(<ul id="pathwayMenu$symbolCount" class="nav tertiary-nav collapse">);
							foreach my $pw (@$pathways) { 
								print qq(<li>);
								print $htmlLinks->generatePathwayLine($pw); 
								print qq(</li>);
								## JSON pathway data -- detail
								$json_doctogo_pathways .= "\t\t\t\t\t{\t\"name\": \"" . $htmlLinks->generatePathwayDescription($pw) . "\",\"link\": \"" . $htmlLinks->generatePathwayLink($pw) . "\"},\n";
							}
							print qq(</ul>);
							print qq(</li>);
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
							print qq(<li class="dropdown">);
							print qq(<a href="#diseaseMenu$symbolCount" class="accordian-toggle" data-toggle="collapse" data-parent="#symbolMenu$symbolCount">Diseases <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
							print qq(<ul id="diseaseMenu$symbolCount" class="nav tertiary-nav collapse">);
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
									print qq(<li class="dropdown">);
									print qq(<a href="#diseaseName$kegg_disease_count" class="accordian-toggle" data-toggle="collapse" data-parent="#diseaseMenu$symbolCount">KEGG:$disease_name <span class="glyphicon glyphicon-triangle-bottom"></span></a>);
									print qq(<ul id="diseaseName$kegg_disease_count" class="nav quaternary-nav collapse">);
										print qq(<li>);
										print $htmlLinks->generateKeggDiseaseLine($kd);
										print qq(</li>);
									print qq(</ul>);
									print qq(</li>);
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
									print qq(<li>);
									print $htmlLinks->generateMedgenDiseaseLine($_);
									print qq(</li>);
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
							print qq(</ul>);
							print qq(</li>);
#						print qq(<div class="annotationSeperator"></div>\n);
						}
					##Close the div to hold all annotations for a symbol
					print qq(</ul>);
					print qq(</li>);
					$symbolCount++;
## Close the gene name openings

					## Finalize the JSON data
					## Remove last comma
					$json_body =~ s/,$//;
					print JSON_DOCTOGO_FILE $json_body;

					print JSON_DOCTOGO_FILE "\t\t]\n";
					## If last element, just print the "}"
					if ($hashKey == $annotated_words_last_key ) { print JSON_DOCTOGO_FILE "\t}\n"; }
					else { print JSON_DOCTOGO_FILE "\t},\n"; }


				}
			}
			print qq(</ul>); # End ul.nav.navmenu-nav
			print qq(</div>); # End div.tab-panel
		}
		print JSON_DOCTOGO_FILE "\t]\n";
		print JSON_DOCTOGO_FILE "}\n";
		close(JSON_DOCTOGO_FILE);

		## This ends writing the JSON data...
		## Get the text from html part 2 file.
		my $part_2_text = read_file('/var/www/Genotation/temp/doctogo_part2.html');
		print STDERR "Trying: $json_doctogo_file\n";
		## Write the second part of the doctogo html file
		append_file($json_doctogo_file, $part_2_text);
		
		## START- printing the drug details
		if ( keys %$annotated_drug_words > 0 )
		{
			## If there are no gene information, but just drugs, the drug information will be shown right away
			if($count == 1){ print qq(<div id="geneDetailContainerDrugs" class="annotationContainer show">); $count++; }
			else { print qq(<div id="geneDetailContainerDrugs" class="annotationContainer hide">); }
			foreach my $drugName(keys %$annotated_drug_words)
			{
				print $htmlLinks->generateDrugHeaderLine( $drugName, $annotated_drug_words->{$drugName}->getAccessionID);
			}
		}
		## END - printing the drugs

		## End -- annotation section
		print qq(</div>); # End div.tab-content
		print qq(</nav>);


		print qq(<script type="text/javascript" src="/JS/min/app-min.js"></script>);
		if($documentType eq "pdf") { 
			#print qq(<script type=\"text/javascript\">$(document).ready( function() { loadPDF("$pdfDocument"); } );</script>); 
			print qq(<script type=\"text/javascript\">loadPDF("$pdfDocument");</script>); 
		}

		## Search functionality for the menu
		print qq(<script src="http://listjs.com/no-cdn/list.js"></script>);		
		print "\<script type=\"text/javascript\">\$(document).ready( function() { var options = { valueNames: [ 'name' ] }; var userList = new List('geneDetailContainerTab', options);});</script>";
			## End -- Body
			print "</body>\n";
		print "</html>\n";		
		

		
sub generateOrganismHtml
{		
	my $symbol = $_[0];
	my $species = $_[1];
	##<!-- All the annotated information goes here -->
			
			## Start -- Annotation gene detail
			## Helper
			
			
	## annotated words contains DBAnnotation objects
	## DBAnnotation:
	##				Symbol
	##				Gene object
	##				annotations hash

	## Symbol display
	print "<a href=\"#\" class=\"catMenu\" onclick=\"showHide(\'symbolMenu$symbol_count\')\"><strong>$symbol($species)</strong><div class=\"apex-dn\"></div></a>\n";
}
