=head1 NAME

EPrints::Plugin::Screen::Admin::RegenEntities

=cut

package EPrints::Plugin::Screen::Admin::RegenEntities;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ regen_entities /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1262, 
			action => "regen_entities",
		},
	];

	return $self;
}

sub allow_regen_entities
{
	my( $self ) = @_;

	return $self->allow( "config/regen_entities" );
}

sub action_regen_entities
{
	my( $self ) = @_;

	my $session = $self->{session};
	
	unless( $session->expire_entities() )
	{
		$self->{processor}->add_message( "error",
			$self->html_phrase( "failed" ) );
		$self->{processor}->{screenid} = "Admin";
		return;
	}
	
	$self->{processor}->add_message( "message",
		$self->html_phrase( "ok" ) );
	$self->{processor}->{screenid} = "Admin";
}	




1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
