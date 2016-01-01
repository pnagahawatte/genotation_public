#!perl -T
use strict;
$|++;

#$ENV{PATH} = "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin";

use CGI qw(:all delete_all escapeHTML);

if (my $session = param('session')) { # returning to pick up session data
  my $cache = get_cache_handle();
  my $data = $cache->get($session);
  unless ($data and ref $data eq "ARRAY") { # something is wrong
	show_form();
	exit 0;
  }
  print header;
  print start_html(-title => "Traceroute Results",
				   ($data->[0] ? () :
					(-head => ["<meta http-equiv=refresh content=5>"])));
  print h1("Traceroute Results");
  print pre(escapeHTML($data->[1]));
  print p(i("... continuing ...")) unless $data->[0];
  print end_html;
} elsif (my $host = param('host')) { # returning to select host
  if ($host =~ /^([a-zA-Z0-9.\-]{1,100})\z/) { # create a session
	$host = $1;                 # untainted now
	my $session = get_session_id();
	my $cache = get_cache_handle();
	$cache->set($session, [0, ""]); # no data yet

	if (my $pid = fork) {       # parent does
	  delete_all();             # clear parameters
	  param('session', $session);
	  print redirect(self_url());
	} elsif (defined $pid) {    # child does
	  close STDOUT;             # so parent can go on
	  unless (open F, "-|") {
		open STDERR, ">&=1";
		exec "/usr/sbin/traceroute", $host;
		die "Cannot execute traceroute: $!";
	  }
	  my $buf = "";
	  while (<F>) {
		$buf .= $_;
		$cache->set($session, [0, $buf]);
	  }
	  $cache->set($session, [1, $buf]);
	  exit 0;
	} else {
	  die "Cannot fork: $!";
	}
  } else {
	show_form();
  }
} else {                        # display form
  show_form();
}

exit 0;

sub show_form {
  print header, start_html("Traceroute"), h1("Traceroute");
  print start_form;
  print submit('traceroute to this host:'), " ", textfield('host');
  print end_form, end_html;
}

sub get_cache_handle {
  require Cache::FileCache;

  Cache::FileCache->new
	  ({
		namespace => 'tracerouter',
		username => 'nobody',
		default_expires_in => '30 minutes',
		auto_purge_interval => '4 hours',
	   });
}

sub get_session_id {
	require Digest::MD5;

	Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
}