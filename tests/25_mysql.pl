use strict;
use Test::More tests => 6;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $session = EPrints::Test::get_test_session( 0 );
ok(defined $session, 'opened an EPrints::Session object');

my $database = $session->get_database();
ok( defined $database, "database defined" );

my $dataset = $session->dataset( "eprint" );

SKIP: {
	skip "Only supports MySQL", 1 unless $database->isa( "EPrints::Database::mysql" );

	ok($database->index_name(
		$dataset->get_sql_table_name,
		$dataset->field( "datestamp" )->get_sql_index
	), "index_name(eprint.datestamp)");
}

ok(1);

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
