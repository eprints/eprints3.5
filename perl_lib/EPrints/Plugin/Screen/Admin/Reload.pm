=head1 NAME

EPrints::Plugin::Screen::Admin::Reload

=cut

package EPrints::Plugin::Screen::Admin::Reload;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ reload_config /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_config", 
			position => 1250, 
			action => "reload_config",
		},
	];

	return $self;
}

sub allow_reload_config
{
	my( $self ) = @_;

	return $self->allow( "config/reload" );
}

sub action_reload_config
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "Admin";

	my $session = $self->{session};

	my( $result, $msg ) = $session->get_repository->test_config;

	if( $result != 0 )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "reload_bad_config",
				output=>$self->{session}->make_text( $msg ) ) );
		return;
	}

	if( !$session->reload_config )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "reload_write_failed" ) );
		return;
	}

	$self->{processor}->add_message( "message",
		$self->html_phrase( "reloaded" ) );

	return 1; # useful for other Screen plugins calling us
}	




1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
