=head1 NAME

EPrints::Plugin::Screen::Admin::RegenAbstracts

=cut

package EPrints::Plugin::Screen::Admin::RegenAbstracts;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ regen_abstracts /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1260, 
			action => "regen_abstracts",
		},
	];

	return $self;
}

sub allow_regen_abstracts
{
	my( $self ) = @_;

	return $self->allow( "config/regen_abstracts" );
}

sub action_regen_abstracts
{
	my( $self ) = @_;

	my $session = $self->{session};
	
	unless( $session->expire_abstracts() )
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
