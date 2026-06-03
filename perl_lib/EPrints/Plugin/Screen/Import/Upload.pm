=head1 NAME

EPrints::Plugin::Screen::Import::Upload - file upload only

=cut

package EPrints::Plugin::Screen::Import::Upload;

@ISA = ( 'EPrints::Plugin::Screen::Import' );

use strict;

sub render
{
	my ( $self ) = @_;

	return $self->render_upload_form;
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
