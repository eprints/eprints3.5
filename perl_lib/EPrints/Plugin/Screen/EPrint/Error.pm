=head1 NAME

EPrints::Plugin::Screen::EPrint::Error

=cut


#remove !
package EPrints::Plugin::Screen::EPrint::Error;

use EPrints::Plugin::Screen::EPrint;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub render
{
	my( $self ) = @_;

	my $chunk = $self->{session}->make_doc_fragment;

	return $chunk;
}

# ignore the form. We're screwed at this point, and are just reporting.
sub from
{
	my( $self ) = @_;

	return;
}

1;


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
