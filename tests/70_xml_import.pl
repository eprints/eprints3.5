=head1 NAME

MyHander

=cut

use strict;
use Test::More tests => 9;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

my $session = EPrints::Test::get_test_session( 0 );
ok(defined $session, 'opened an EPrints::Session object (noisy, no_check_db)');

{
package MyHander;

sub new { bless {}, shift; }

sub message
{
	my( $self, $type, $xml ) = @_;

	my $mess = EPrints::XML::to_string( $xml );
	EPrints::XML::dispose( $xml );

	push @{$self->{$type}||=[]}, $mess;
}
}

my $doc = EPrints::XML::parse_xml_string( join "", <DATA> );
my( $eprint_xml ) = $doc->documentElement->getElementsByTagName( "eprint" );

my $handler = MyHander->new;
my $epdata = EPrints::DataObj::EPrint->xml_to_epdata( $session, $eprint_xml, Handler => $handler );

is( $epdata->{title}, "Fulvous Whistling Ducks and Man", "Parsed title" );
is( $epdata->{creators}->[0]->{name}->{family}, "Toda", "Parsed 1st creator" );

my %warnings = (
	bad_field => 0,
	bad_document => 0,
	bad_item => 0,
	bad_name_part => 0
	);
foreach my $warning (@{$handler->{warning}})
{
	while(my( $key, $value ) = each %warnings)
	{
		$warnings{$key} = 1 if $warning =~ /$key/;
	}
}

foreach my $test (sort keys %warnings)
{
	ok( $warnings{$test}, "Invalid XML element: $test" );
}

EPrints::XML::dispose( $doc );

$session->terminate;


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
