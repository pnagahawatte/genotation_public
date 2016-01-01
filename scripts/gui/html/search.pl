#!/usr/bin/perl -w

use lib "/var/www/Genotation/scripts";

use CGI;
use web_mining::Search::pubmed::Article;
use web_mining::Search::pubmed::Search;
use web_mining::Search::common::SearchResult;

my $MAX_SEARCH_RECORDS = 40;
print "Content-Type: text/html\n\n";

my $q = CGI->new();
## Get the search terms through the query string
my $terms = $q->param('terms');

## Counters used in identifying div's
my $kegg_disease_count = 0;

print "<!DOCTYPE html>";
print "<html>";
	## Start -- Head
	print "<head>";
		print "<title>Genotation Search results</title>";
		# print qq(<link rel="stylesheet" type="text/css" href="res/searchStyle.css">);
		# print qq(<link href="http://fonts.googleapis.com/css?family=Vollkorn" rel="stylesheet" type="text/css">);
		# print qq(<link rel="stylesheet" type="text/css" href="res/menuStyle.css">);
		# print qq(<link rel="stylesheet" type="text/css" href="res/style.css">);
		print qq(<link rel="icon" href="res/favicon.ico" type="image/x-icon"/>);
		print qq(<link rel="shortcut icon" href="res/favicon.ico" type="image/x-icon"/>);
		print qq(<link rel="stylesheet" type="text/css" href="stylesheets/styles.css">);
		# print qq(<script src="JS/main.js"></script>);
	print "</head>";
	## End -- Head
	
	## Start -- Body
	print "<body>";

		print qq(<nav class="navbar navbar-inverse navbar-lg">);
			print qq(<div class="navbar-header">);
				print qq(<a class="navbar-brand" href="/">Genotation</a>);
			print qq(</div>); # End .navbar-header

			print qq(<form class="navbar-form navbar-left" role="search" action="">);
				print qq(<div class="form-group header-search-bar">);
					print qq(<input type="text" class="form-control" placeholder="Search" value="$terms" name="terms" />);
				print qq(</div>);
				print qq(<button type="submit" class="btn btn-default">Search</button>);
			print qq(</form>);
		print qq(</nav>); # end .navbar.navbar-inverse


		# print qq(<div class="content-box">);
		# 	print qq(<input type="text" name="terms" class="resultInputBox" value="$terms"></input>);
		# 	print qq(<div id="ribbon-container">);
		# 		print qq(<a href="search.pl" id="ribbon">Genotation</a>);
		# 	print qq(</div>);
		# print qq(</div>);
		## Do the search via pubmed central
		my $search = web_mining::Search::pubmed::Search->new("$terms", $MAX_SEARCH_RECORDS); ## Search terms and maxRecords
		my ($results) =  $search->getSearchResults();

		print qq(<div class="container">);
			print qq(<div class="row">);
				print qq(<div class="col-sm-12">);
					my $numResults = scalar @$results;
					print qq(<p class="search-results-description">Your search returned $numResults results</p>);
				print qq(</div>);
			print qq(</div>);
			foreach (@$results) 
			{
				print qq(<div class="row">);
					print qq(<div class="col-sm-12">);
						print qq(<div class="search-result">);
							## Get details about each search result
							my $title = $_->getTitle();
							my $description = $_->getDescription();
							my $link = $_->getLink();
							
							
							## We need the user to go to DisplayAnnotations
							## when they select a link...
							my $article = web_mining::Search::pubmed::Article->new($link);
							my $pdfLink = $article->getUriPdf();
							my $showLink = "DisplayAnnotation.pl?pmcurl=$pdfLink";
							print qq(<a href="$showLink">$title</a>);
							print qq(<p>$description<p>);
						print qq(</div>);
					print qq(</div>);
				print qq(</div>);
			}
		print qq(</div>);
		print qq(<script type="text/javascript" src="/JS/min/app-min.js"></script>);
	print "</body>";
print "</html>";