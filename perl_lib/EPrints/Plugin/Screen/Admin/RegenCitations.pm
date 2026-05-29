=head1 NAME

EPrints::Plugin::Screen::Admin::RegenCitations

=cut

package EPrints::Plugin::Screen::Admin::RegenCitations;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ regen_citations /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1265, 
			action => "regen_citations",
		},
	];

	return $self;
}

sub allow_regen_citations
{
	my( $self ) = @_;

	return 0 unless defined $self->{session}->config( "citation_caching", "enabled" ) && $self->{session}->config( "citation_caching", "enabled" );

	return $self->allow( "config/regen_citations" );
}

sub action_regen_citations
{
	my( $self ) = @_;

	my $session = $self->{session};
	
	unless( $session->expire_citations() )
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
