=head1 NAME

EPrints::Plugin::Screen::Staff::EPrintSearch

=cut


package EPrints::Plugin::Screen::Staff::EPrintSearch;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{
			place => "admin_actions_editorial",
			position => 500,
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "eprint/search/staff" );
}

sub from
{
	my( $self ) = @_;

	$self->{processor}->{redirect} = $self->repository->current_url(
			host => 1,
			path => "cgi",
			"search/eprint/staff"
		);
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
