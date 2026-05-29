=head1 NAME

EPrints::Plugin::Screen::User::SavedSearches

=cut


package EPrints::Plugin::Screen::User::SavedSearches;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 300,
		},
		{
			place => "user_actions",
			position => 200,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "saved_search" );
}

sub from
{
	my( $self ) = @_;

	my $url = URI->new( $self->{session}->current_url( path => "cgi", "users/home" ) );
	$url->query_form(	
		screen => "Listing",
		dataset => "saved_search",
		userid => $self->{session}->current_user->id,
	);

	$self->{session}->redirect( $url );
	exit;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
