#!perl
package gui::html::parsers::parse_pdf;
use warnings;
use strict;
use LWP::Simple;
use LWP::UserAgent;
use File::Basename;
    
sub new
{
	my $class = shift;
	my $self = { _pdf_file => shift };
	bless $self, $class;
	return $self;
}

sub getPdfText
{
	## Get the class and the pdf file link
	my $self = $_[0];
	my $pdf_link = $self->{_pdf_file};

	## Find out the file name without the .pdf extension
	my $pdf_filename = "/var/www/Genotation/temp/" . basename("$pdf_link", ".pdf");
#	my $pdf_filename = "" . basename("$pdf_link", ".pdf");
	## Download the pdf file and convert to txt
		## Check if a file is a link
	if ( $pdf_link =~ /^ftp/)
	{
		print STDERR "pdf link $pdf_link\n";	
		my $client = LWP::UserAgent->new();
		my $capture = $client->get("$pdf_link", ":content_file" => "$pdf_filename.pdf");
		## Change the pdf link to be the downloaded file name
		## which will keep the flow simple for the rest of the script
		$pdf_link = "$pdf_filename.pdf";
	}

	system("pdftotext $pdf_link");
	#my $epoc = time();
	#my $txt_filename = "$pdf_filename-gn-$epoc.txt";
	
	## Return the txt file name
#	return $txt_filename;
	return $pdf_filename . ".txt";
}

return "true";
