=head1 NAME

EPrints::Plugin::Screen::Admin::Config::View::XPage

=cut

package EPrints::Plugin::Screen::Admin::Config::View::XPage;

use EPrints::Plugin::Screen::Admin::Config::View::XML;

@ISA = ( 'EPrints::Plugin::Screen::Admin::Config::View::XML' );

use strict;

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/view/static" );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
