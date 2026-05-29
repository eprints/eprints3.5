=head1 NAME

EPrints::Plugin::Screen::User::View

=cut


package EPrints::Plugin::Screen::User::View;

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
			position => 200,
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 if !defined $self->{session}->current_user;
	return $self->{session}->current_user->allow( "user/view", $self->{session}->current_user );
}

sub from
{
	my( $self ) = @_;

	my $userid = $self->{session}->param( "userid" );
	$userid = $self->{session}->current_user->id if !defined $userid;

	my $url = $self->{session}->current_url( path => "cgi", "users/home" );
	$url->query_form(
		screen => 'Workflow::View',
		dataset => 'user',
		dataobj => $userid,
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
