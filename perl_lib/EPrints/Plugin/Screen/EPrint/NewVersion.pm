=head1 NAME

EPrints::Plugin::Screen::EPrint::NewVersion

=cut

package EPrints::Plugin::Screen::EPrint::NewVersion;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	#	$self->{priv} = # no specific priv - one per action

	$self->{actions} = [qw/ new_version /];

	$self->{appears} = [
{ place => "eprint_actions", 	action => "new_version", 	position => 500, },
	];

	return $self;
}

sub about_to_render 
{
	my( $self ) = @_;

	$self->EPrints::Plugin::Screen::EPrint::View::about_to_render;
}

sub allow_new_version
{
	my( $self ) = @_;

	return $self->allow( "eprint/derive_version" );
}

sub action_new_version
{
	my( $self ) = @_;

	my $inbox_ds = $self->{session}->get_archive()->get_dataset( "inbox" );
	my $copy = $self->{processor}->{eprint}->clone( $inbox_ds, 1 );
	$copy->set_value( "userid", $self->{session}->current_user->get_value( "userid" ) );
	$copy->commit();

	$self->{processor}->add_message( "message",
		$self->html_phrase( "success" ) );

	$self->{processor}->{eprint} = $copy;
	$self->{processor}->{eprintid} = $copy->get_id;
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
