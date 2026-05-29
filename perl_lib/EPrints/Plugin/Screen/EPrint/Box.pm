=head1 NAME

EPrints::Plugin::Screen::EPrint::Box

=cut

package EPrints::Plugin::Screen::EPrint::Box;

our @ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	# Register sub-classes but not this actual class.
	if( $class ne "EPrints::Plugin::Screen::EPrint::Box" )
	{
		$self->{appears} = [
			{
				place => "summary_right",
				position => 1000,
			},
		];
	}

	return $self;
}

sub render_collapsed { return 0; }

sub can_be_viewed { return 1; }

sub can_be_previewed { return 1; }

sub render
{
	my( $self ) = @_;

	return $self->{session}->make_text( "Please add a 'render' method to this box!" );
}

1;


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
