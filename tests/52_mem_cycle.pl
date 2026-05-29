#!/usr/bin/perl

use Test::More tests => 3;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }

unless(eval "use Test::Memory::Cycle; 1")
{
	BAIL_OUT "Install Test::Memory::Cycle";
}

my $repoid = EPrints::Test::get_test_id();

my $eprints;
my $repository;

# we load twice to check that reloading a repository won't cause cycles to
# appear
for(0..1)
{
	undef $eprints;
	undef $repository;
	$eprints = EPrints->new;

	$repository = $eprints->repository( $repoid );
}

# do a load_config() to check that doesn't cause issues
$repository->load_config();

memory_cycle_ok( $repository, "Reference cycles after load_config" );

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
