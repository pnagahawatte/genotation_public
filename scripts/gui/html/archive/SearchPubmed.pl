#!perl -I "//sonas01/clusterhome/pnagahaw/scripting/gene_names/scripts/"
#Path for the WAMP perl executable: C:\wamp\bin\perl\bin\perl

use CGI;
use warnings;
use strict;

use WWW::Search;

my $wwwSearch = new WWW::Search('NCBI::Pubmed');

$wwwSearch->maximum_to_retrieve(10);

  $wwwSearch->native_query( my $query_pubmed = 'estradiol [NM]' );

  while ( my $r = $wwwSearch->next_result )
  {
     print "$_\n" for ( $r->url, $r->title, $r->description );
  }