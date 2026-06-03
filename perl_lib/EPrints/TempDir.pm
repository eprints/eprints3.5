######################################################################
#
# EPrints::TempDir
#
######################################################################
#
#
######################################################################

package EPrints::TempDir;

use File::Temp;

use strict;

=pod

=head1 NAME

EPrints::TempDir - Create temporary directories that are removed automatically

=head1 DESCRIPTION

DEPRECATED

Use C<<File::Temp->newdir()>>;

=head1 SEE ALSO

L<File::Temp>

=cut

sub new
{
	my $class = shift;

	return File::Temp->newdir( @_, TMPDIR => 1 );
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
