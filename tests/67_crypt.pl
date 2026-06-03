use Test::More tests => 5;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $session = EPrints::Test::get_test_session();

my $password = "bears love picnics";

my $crypt = EPrints::Utils::crypt_password( $password, $session );
ok($crypt =~ /^\?/, "crypt is typed");
my $uri = URI->new( $crypt );
ok(length({$uri->query_form}->{digest}), "digest is non-blank");

ok(EPrints::Utils::crypt_equals( $crypt, $password ), "password matches");

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
