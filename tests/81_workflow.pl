use strict;
use Test::More tests => 4;

# this is only really useful for profiling (we can't test the GUI output)

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }
BEGIN { use_ok( "EPrints::ScreenProcessor" ); }

my $session = EPrints::Test::get_test_session();

# find an example eprint
my $dataset = $session->dataset( "eprint" );
my $eprint = EPrints::Test::get_test_dataobj( $dataset );

my $workflow = EPrints::Workflow->new( $session, 'default',
	item => $eprint,
);
my @stages = $workflow->get_stage_ids;

foreach my $stage (@stages)
{
	$session = EPrints::Test::OnlineSession->new( $session, {
		method => "GET",
		path => "/cgi/users/home",
		username => "admin",
		query => {
			screen => "EPrint::Edit",
			eprintid => $eprint->id,
			stage => $stage,
		},
	});
	EPrints::ScreenProcessor->process(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home"
		);

	my $content = $session->test_get_stdout();
}

#diag($content);

ok(1);

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
