package SQL::CONN::db_connect;
#@ISA = ('Exporter');
#@EXPORT = ('db_connect');
#our @EXPORT_OK = qw(db_connect);

use DBI;
sub get_connection{
	

	my $database = "gene";
        my $host = "";
        my $opt_user = "";
        my $port = 3306;
        my $password = "";
        my $dbh = DBI->connect("dbi:mysql:dbname=" . $database. ";host=".$host.";port=".$port.";", $opt_user,$password, {RaiseError => 1, AutoCommit => 0});
	return ($dbh);
}
return "true";
