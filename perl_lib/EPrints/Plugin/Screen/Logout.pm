=head1 NAME

EPrints::Plugin::Screen::Logout

=cut

package EPrints::Plugin::Screen::Logout;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
# See cfg.d/dynamic_template.pl
#		{
#			place => "key_tools",
#			position => 10000,
#		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return defined $self->{session}->current_user;
}

sub render_action_link
{
	my( $self, %opts ) = @_;

	$opts{uri} = $self->{session}->config( "http_cgiroot" ) . "/logout";
	return $self->SUPER::render_action_link( %opts );
}

sub render
{
	my( $self ) = @_;

	my $xml = $self->{session}->xml;

	my $frag = $xml->create_document_fragment;

	$frag->appendChild( $self->{session}->render_message(
		"message",
		$self->html_phrase( "success" )
	) );

	$frag->appendChild( $self->{session}->html_phrase( "general:frontpage_link" ) );

	return $frag;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
