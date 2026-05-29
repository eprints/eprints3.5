######################################################################
#
# EPrints::System::linux
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::System::darwin> - Wrappers for Darwin system calls.

=head1 DESCRIPTION

This class provides Darwin-specific system calls required by EPrints.

This class inherits from L<EPrints::System>.

=head1 INSTANCE VARIABLES

See L<EPrints::System|EPrints::System#INSTANCE_VARIABLES>.

=head1 METHODS

None, as L<EPrints::System> methods do not need to be modified to work
with Darwin.

=cut
######################################################################

package EPrints::System::darwin;

@ISA = qw( EPrints::System );

use strict;

1;

######################################################################
=pod

=head1 SEE ALSO

L<EPrints::System>

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
