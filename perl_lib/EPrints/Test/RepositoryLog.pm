package EPrints::Test::RepositoryLog;

=head1 NAME

EPrints::Test::RepositoryLog - capture repository log messages

=cut

use strict;

our @logs;

{
no warnings;
sub EPrints::Repository::log
{
	my( $repo, $msg ) = @_;

	push @logs, $msg;
}
}

sub logs
{
	my @r = @logs;
	@logs = ();

	return @r;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
