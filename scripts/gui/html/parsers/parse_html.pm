#!perl
package gui::html::parsers::parse_html;
use warnings;
use strict;
use LWP::Simple;
use LWP::UserAgent;
use File::Basename;
use HTML::Parser ();
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;

sub new
{
	my $class = shift;
	my $self = { _html_file => shift };
	bless $self, $class;
	return $self;
}

sub getHtmlText
{
	## Get the class and the pdf file link
	my $self = $_[0];
	my $htmlLink = $self->{_html_file};
	
	## Find out the file name without the .html extension
	my $htmlFilename = basename("$htmlLink", ".html");
	
	## Download the html file and convert to txt
	#my $client = LWP::UserAgent->new();
	#my $capture = $client->get("$htmlLink", ":content_file" => "$htmlFilename.html");
	my $epoc = time();
	my $txtFilename = "/var/www/Genotation/temp/$htmlFilename-gn-$epoc.txt";
	#$self->htmlToText("$htmlFilename.html", $txtFilename);
	$self->htmlToText($htmlLink, $txtFilename);
	## Return the txt file name
	return $txtFilename;
}

sub htmlToText
{
	my $self = $_[0];
	my $htmlLink = $_[1];
	my $txtFileName = $_[2];
	# Create parser object
	#my $p = HTML::Parser->new( api_version => 3,
     #                    start_h => [\&start, "tagname, attr"],
      #                   end_h   => [\&end,   "tagname"],
       #                  marked_sections => 1,
        #               );
	# Parse directly from file
	#$p->parse_file($htmlFileName);
	
	my $mech = WWW::Mechanize->new();
	WWW::Mechanize::TreeBuilder->meta->apply($mech);
	$mech->get($htmlLink);
	my @pList = $mech->find('p');
	
	
	
	open FILE, ">$txtFileName" or die 
		"gui::html::parsers::parse_html file $txtFileName $!\n";
		
	## Make sure to set the input mode
	binmode( FILE, ':encoding(utf8)');
	foreach(@pList) 
	{ 
		print FILE $_->as_text() . "\n";
	}
	close FILE;
}

return "true";