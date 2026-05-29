use strict;
use Test::More tests => 4;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "EPrints::ScreenProcessor" ); }

my $session = EPrints::Test::get_test_session();
$session = EPrints::Test::OnlineSession->new( $session, {
	method => "GET",
	path => "/cgi/users/home",
	username => "admin",
});

EPrints::ScreenProcessor->process(
	session => $session,
	url => $session->config( "base_url" ) . "/cgi/users/home"
	);

$session->terminate;

my $content = $session->test_get_stdout();

#diag($content);

ok(1);

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
