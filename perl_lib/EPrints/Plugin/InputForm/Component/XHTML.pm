=head1 NAME

EPrints::Plugin::InputForm::Component::XHTML

=cut

package EPrints::Plugin::InputForm::Component::XHTML;

use EPrints::Plugin::InputForm::Component;

@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "XHTML";
	$self->{visible} = "all";
	$self->{surround} = "Light" unless defined $self->{surround};
	return $self;
}

=pod

=item $bool = $component->parse_config( $dom )

Parses the supplied DOM object and populates $component->{config}

=cut

sub parse_config
{
	my( $self, $dom ) = @_;

	$self->{config}->{dom} = $dom;
}

=pod

=item $content = $component->render_content()

Returns the DOM for the content of this component.

=cut


sub render_content
{
	my( $self ) = @_;

	return EPrints::XML::contents_of( $self->{config}->{dom} );
}

1;






=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
