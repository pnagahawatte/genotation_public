#!perl -I "//sonas01/clusterhome/pnagahaw/scripting/gene_names/scripts/"
#Path for the WAMP perl executable: C:\wamp\bin\perl\bin\perl
use CGI;
#use warnings;
#use strict;
#use lib "//sonas01/clusterhome/pnagahaw/scripting/gene_names/scripts/";
use gui::html::parse_pdf;
use gui::html::HtmlLinks;
use word_search::TagWords;
use List::MoreUtils 'uniq';


#open (STDERR, ">&STDOUT");
print "Content-Type: text/html\n\n";

my $q = CGI->new();
my $url = $q->param('url');

## Counters used in identifying div's
my $symbol_count = 0;
my $kegg_disease_count = 0;

print "<!DOCTYPE html>\n";
print "<html>\n";
	## Start -- Head
	print "<head>\n";
		print "<title>Annotation</title>\n";
		print qq(<link rel="stylesheet" type="text/css" href="res/style.css">\n);
		print qq(<link rel="stylesheet" type="text/css" href="res/menuStyle.css">\n);
		print qq(<script type="text/javascript" src="JS/pdfobject.js"></script>\n);
		print qq(<script src="JS/main.js"></script>\n);
	print "</head>\n";
	## End -- Head
	
	## Start -- Body
	print "<body>\n";
		## Start -- main menu
		## REFACTOR: THIS IS WHERE WE WILL CHECK FOR THE DOCUMENT TYPE
		my $pdf = gui::html::parse_pdf->new("$url");
		my $txt_filename = $pdf->getPdfText();
		my $tagWords = word_search::TagWords->new($txt_filename);
		my ($annotated_words) = $tagWords->getAnnotations();
		
		## Done with the text file.. delete it
		unlink "$txt_filename";
		
		print qq(<div id="menuContainer">\n);
			print qq(<a href="#" onclick="toggle_visibility('detailsContainer');"><div id="lines" class="btn"></div></a>\n);
			print qq(<a href="#"><h1 class="homeTitle">Annotations</h1></a>\n);
		print "</div>\n";
		## End -- main menu
		
		## Start -- Document display
		print qq(<div id="documentContainer" class="documentContainer">\n);
			##<!--iframe id="docFrame" src="http://www.nature.com/nrd/journal/v13/n7/pdf/nrd4326.pdf">Your browser does not support iFrames. 
			##Please use the newest version of Chrome, Mozilla, IE</iframe-->
			print "<script>loadPDF(\"$url\");</script>\n";			
		print "</div>\n";
		## End -- Document display
	
		## Start -- annotation section
		print qq(<div id="detailsContainer" class="hide">\n);
			##<!-- All the annotated information goes here -->
			
			## Start -- Annotation top menu
			#print qq(<ul class="tabList">\n);
			#	print qq(<li id="current" onclick="toggle_menu_visibility('geneDetailContainer', 'drugDetailContainer');"><a href="#">Genes</a></li>\n);
			#	print qq(<li ><a href="#" onclick="toggle_menu_visibility('drugDetailContainer', 'geneDetailContainer');">Diseases</a></li>\n);
			#print qq(</ul>\n);
			## End -- Annotation top menu
			
			## Start -- Annotation gene detail
			## Helper
			my $htmlLinks = gui::html::HtmlLinks->new();
			
			## Gene detail container -- start
			print qq(<div id="geneDetailContainer" class="annotationContainer">\n);
				print qq(<div class="catDiv"></div>\n);
				## annotated words contains DBAnnotation objects
				## DBAnnotation:
				##				Symbol
				##				Gene object
				##				annotations hash
				foreach (keys %$annotated_words)
				{
					my $symbol = $annotated_words->{$_}->getSymbol();
					my $species = $annotated_words->{$_}->getGene()->getSpecies();
					## Symbol display
					print "<a href=\"#\" class=\"catMenu\" onclick=\"showHide(\'symbolMenu$symbol_count\')\"><strong>$symbol($species)</strong><div class=\"apex-dn\"></div></a>\n";
					## Gene container
					print qq(<div id="symbolMenu$symbol_count" class="hide">\n);
						print qq(<p class="annotationTextbox"> This is where the gene description will be </p> <!--auto-generated-->\n);
						print qq(<div class="annotationSeperator"></div>\n);
						
						## Collect the synonyms and print in an expandable div
						print "<a href=\"#\" class=\"catSubmenu\" onclick=\"showHide(\'synonymMenu$symbol_count\')\"><strong>Synonyms</strong><div class=\"apex-dn\"></div></a>\n";
						print qq(<div id="synonymMenu$symbol_count" class="hide">\n);
							my ($synonyms) = $annotated_words->{$_}->getAnnotations()->{synonyms};
							foreach (@$synonyms) { print "$_,"; }
						print qq(</div>\n);
						print qq(<div class="annotationSeperator"></div>\n);
						
						## Collect the pathways and print in an expandable div
						print "<a href=\"#\" class=\"catSubmenu\" onclick=\"showHide(\'pathwayMenu$symbol_count\')\"><strong>Pathways</strong><div class=\"apex-dn\"></div></a>\n";
						print qq(<div id="pathwayMenu$symbol_count" class="hide">\n);
							my ($pathways) = $annotated_words->{$_}->getAnnotations()->{pathways};
							foreach (@$pathways) { print $htmlLinks->generatePathwayLine($_) ."\n"; }
						print qq(</div>\n);
						print qq(<div class="annotationSeperator"></div>\n);
						
						## Collect the diseases and print in an expandable div
						print "<a href=\"#\" class=\"catSubmenu\" onclick=\"showHide(\'diseaseMenu$symbol_count\')\"><strong>Diseases</strong><div class=\"apex-dn\"></div></a>\n";
						print qq(<div id="diseaseMenu$symbol_count" class="hide">\n);
							## Display the KEGG diseases
							my ($keggDiseases) = $annotated_words->{$_}->getAnnotations()->{keggDiseases};						
							foreach (@$keggDiseases) { 
								my @fields = split ";", $_;
								my $disease_name = $fields[0];
								print "<a href=\"#\" class=\"detailSubmenu\" onclick=\"showHide(\'diseaseName$kegg_disease_count\')\"><strong>KEGG:$disease_name</strong><div class=\"apex-dn\"></div></a>\n";
								print qq(<div id="diseaseName$kegg_disease_count" class="hide">\n);
									print $htmlLinks->generateKeggDiseaseLine($_) ."\n";
								print qq(</div>\n);
								print qq(<div class="annotationSeperator"></div>\n);
								$kegg_disease_count++;
							}
							## Display the Medgen diseases
							my ($medgenDiseases) = $annotated_words->{$_}->getAnnotations()->{medgenDiseases};
							my @uniqueMedgenRecords = uniq (@$medgenDiseases);
							foreach (@uniqueMedgenRecords) { 
								my @fields = split ";", $_;
								my $disease_name = $fields[0];
								print $htmlLinks->generateMedgenDiseaseLine($_);
								print qq(<div class="annotationSeperator"></div>\n);
								$kegg_disease_count++;
							}
							print qq(</div>\n);
						print qq(<div class="annotationSeperator"></div>\n);
					## End - gene container
					print qq(</div>\n);
					$symbol_count++;
				}
			print qq(</div>\n);
			## End -- Annotation gene detail
			
			## Start -- Annotation drug detail
			print qq(<div id="drugDetailContainer" class="hide annotationContainer">\n);
				print qq(<p> This is the drug container</p>\n);
			print qq(</div>\n);
			## End -- Annotation drug detail
			
		print qq(</div>\n);
		## End -- annotation section
	
	## End -- Body
	print "</body>\n";
print "</html>\n";

