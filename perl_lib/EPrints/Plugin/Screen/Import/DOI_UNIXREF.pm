=head1 NAME

EPrints::Plugin::Screen::Import::DOI_UNIXREF

=cut

package EPrints::Plugin::Screen::Import::DOI_UNIXREF;

@ISA = ( 'EPrints::Plugin::Screen::Import' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ test_data import_data /];

	return $self;
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $frag = $xml->create_document_fragment;

	$frag->appendChild( $self->html_phrase( "help" ) );

	$frag->appendChild( $self->render_import_form );

	return $frag;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
