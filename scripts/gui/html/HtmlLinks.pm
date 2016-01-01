#!perl 
package gui::html::HtmlLinks;

use CGI;
use warnings;
use strict;

## REFACTOR - MAKE PRIVATE VARIABLE OF CLASS
my %urls = ( 	'KEGG' , 'http://www.genome.jp/kegg-bin/show_pathway?',
				'KEGG_DISEASE', 'http://www.kegg.jp/dbget-bin/www_bget?ds:',
				'MEDGEN_CONDITIONS', 'http://www.ncbi.nlm.nih.gov/gtr/conditions/',
				'PHARMGKB_DRUG', 'https://www.pharmgkb.org/drug/',
				'DBSNP', 'http://www.ncbi.nlm.nih.gov/SNP/snp_ref.cgi?searchType=adhoc_search&type=rs&rs=',
				'UNIPROT', 'http://www.uniprot.org/uniprot/',
				'PHARMGKB', 'https://www.pharmgkb.org/drug/');
				
sub new
{
	my $class = shift;
	my $self = { };
	bless $self, $class;
	return $self;
}

sub generatePathwayLine
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	## Fields corresponds to the following:
	## $fields[0] = pathway id
	## $fields[1] = pathway description
	## $fields[2] = pathway origin (KEGG, Ingenuity, Wiki)
	my $link = $urls{$fields[2]};
	my $pathwayDescription = $fields[1];
	$pathwayDescription =~ s/-Homesapiens(human)//;
	my $pathwayID = $fields[0];
	my $pathwayLine = "<a href=\"$link$pathwayID\" target=\"_blank\"><p class=\"annotationText\">$pathwayDescription<\/p><\/a>";
	return $pathwayLine;
}

sub generatePathwayLink
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	## Fields corresponds to the following:
	## $fields[0] = pathway id
	## $fields[1] = pathway description
	## $fields[2] = pathway origin (KEGG, Ingenuity, Wiki)
	my $link = $urls{$fields[2]};
	my $pathwayID = $fields[0];
	return "$link$pathwayID";
}

sub generatePathwayDescription
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	my $pathwayDescription = $fields[1];
	$pathwayDescription =~ s/-Homesapiens(human)//;
	return "$pathwayDescription";
}

sub generateKeggDiseaseLine
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	## $fields[0] = name
	## $fields[1] = description
	## $fields[2] =  category
	## $fields[3] = envFactor
	## $fields[4] = comment
	## $fields[5] = kegg disease id
	my $link = $urls{"KEGG_DISEASE"};
	my $diseaseName = $fields[0];
	my $description = $fields[1];
	my $keggDiseaseID = $fields[3];
	$keggDiseaseID =~ s/^\s*//;
	my $pathwayLine = "<a href=\"$link$keggDiseaseID\" target=\"_blank\" class=\"largeParagraphtext\"><p>$description<\/p><\/a>";
	#$pathwayLine .= "<p></p>";
	return $pathwayLine;
}

sub generateKeggDiseaseLink
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	my $link = $urls{"KEGG_DISEASE"};
	my $keggDiseaseID = $fields[3];
	$keggDiseaseID =~ s/^\s*//;
	return "$link$keggDiseaseID";
}

sub generateMedgenDiseaseLine
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	## $row[0] = medgenID
	## $row[1] = diseaseName
	## $row[2] =  diseaseMIM
	my $link = $urls{"MEDGEN_CONDITIONS"};
	my $medgenID = $fields[0];
	my $diseaseName = $fields[1];
	## Remove any numbers at the end
	$diseaseName =~ s/[0-9]//;
	my $diseaseMIM = $fields[3];
	my $medgenDiseaseLine = "<a class=\"detailSubmenu\" href=\"$link$medgenID\" target=\"_blank\">Medgen:$diseaseName<\/a>";
	#$pathwayLine .= "<p></p>";
	return $medgenDiseaseLine;
}

sub generateMedgenDiseaseLink
{
	## Get the class and the line of text
	my $self = $_[0];
	my $line = $_[1];
	## Split the pathways result line
	my @fields = split ";", $line;
	my $link = $urls{"MEDGEN_CONDITIONS"};
	my $medgenID = $fields[0];
	return "$link$medgenID";
}

sub generateSymbolHeaderLine
{
	## Get the class and the line of text
	my $self = $_[0];
	my $symbol = $_[1];
	my $species = $_[2];
	my $symbolCount = $_[3];
	my $htmlCode = "<a href=\"#\" class=\"catMenu\" onclick=\"showHide(\'symbolMenu$symbolCount\')\">$symbol($species)<div class=\"apex-dn\"></div></a>";
	return $htmlCode;
}

sub generateDrugHeaderLine
{
	## Get the class and the line of text
	my $self = $_[0];
	my $drugName = $_[1];
	my $accessionID = $_[2];
	my $link = $urls{"PHARMGKB_DRUG"};
	my $htmlCode = "<a href=\"$link$accessionID#tabview=tab1&subtab=31\" target=\"_blank\" class=\"catMenu\">\u$drugName<\/a>";
	return $htmlCode;
}

sub generateVariantLine
{
	my $self = $_[0];
	my $variant = $_[1];
	my @fields = split ";", $variant;
	my $rsID = $fields[1];
	my $chr = $fields[2];
	my $pos = $fields[3];
	my $link = $urls{"DBSNP"};
	my $htmlCode = "<a href=\"$link$rsID\" target=\"_blank\" class=\"catMenu\">\uchr$chr:$pos<\/a>";
	return $htmlCode;
}

sub generateVariantLink
{
	my $self = $_[0];
	my $variant = $_[1];
	my @fields = split ";", $variant;
	my $rsID = $fields[1];
	my $chr = $fields[2];
	my $pos = $fields[3];
	my $link = $urls{"DBSNP"};
	return "$link$rsID";
}

sub generateVariantrsID
{
	my $self = $_[0];
	my $variant = $_[1];
	my @fields = split ";", $variant;
	my $rsID = $fields[1];
	return "$rsID";
}

sub generateUniprotLine
{
	my $self = $_[0];
	my $protein = $_[1];
	my @fields = split ";", $protein;
	my $uniprotEntry = $fields[0];
	my $description = $fields[1];
	my $link = $urls{"UNIPROT"};
	my $htmlCode = "<a href=\"$link$uniprotEntry\" target=\"_blank\" class=\"catMenu\">\u$description<\/a>";
	return $htmlCode;
}

sub generateUniprotLink
{
	my $self = $_[0];
	my $protein = $_[1];
	my @fields = split ";", $protein;
	my $uniprotEntry = $fields[0];
	my $link = $urls{"UNIPROT"};
	return "$link$uniprotEntry";
}

sub generateUniprotDescription
{
	my $self = $_[0];
	my $protein = $_[1];
	my @fields = split ";", $protein;
	my $description = $fields[1];
	return "$description";
}

sub generatePharmGKBLine
{
	my $self = $_[0];
	my $drug = $_[1];
	my @fields = split ";", $drug;
	my $entityName = $fields[0];
	my $entityID = $fields[1];
	my $link = $urls{"PHARMGKB"};
	my $htmlCode = "<a href=\"$link$entityID#tabview=tab1&subtab=32\" target=\"_blank\" class=\"catMenu\">\u$entityName<\/a>";
	return $htmlCode;
}

sub generatePharmGKBLink
{
	my $self = $_[0];
	my $drug = $_[1];
	my $link = $urls{"PHARMGKB"};
	my @fields = split ";", $drug;
	my $entityID = $fields[1];
	return "$link$entityID#tabview=tab1&subtab=32";
}

sub generatePharmGKBDescription
{
	my $self = $_[0];
	my $drug = $_[1];
	my @fields = split ";", $drug;
	my $description = $fields[0];
	return "$description";
}
#sub generate
return "true";