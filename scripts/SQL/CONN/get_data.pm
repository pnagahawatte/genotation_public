@ISA = ('Exporter');
@EXPORT = ('db_connect');

use Getopt::Long;
use Data::Dumper;
use DBI;

use db_connect;
my $dbh = db_connect();

## This script will take a line at a time in the following format:
## gene_symbol other_fileds(variable)
##
## The script will query the database to find its internal id
## Then print out a line as follows:
## internal_id	other_fileds(variable)
##
## NOTE: If the symbol is not found in the database, the source line
## will not be printed

while(<STDIN>)
{
	my @fields = split "\t", $_;
	my $gene_symbol = $fields[0];
	## Get the internal id for a given symbol
	my $query = "select gneomeID from genemain where symbol =\'$gene_symbol\'";
	my $query_handle = $dbh->prepare($query);

	$query_handle->execute() or die "Could not execute statement: " . $query_handle->errstr;

	if($query_handle->rows != 0)
	{
		$query_handle->bind_columns(undef, \$gneomeID);
		while($query_handle->fetch()) {
		   print "$gneomeID	$_";
		}
	} 
}
$dbh->disconnect();
