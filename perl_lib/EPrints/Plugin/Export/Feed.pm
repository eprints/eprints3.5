=head1 NAME

EPrints::Plugin::Export::Feed

=cut

package EPrints::Plugin::Export::Feed;

use EPrints::Plugin::Export::XMLFile;

@ISA = ( "EPrints::Plugin::Export::XMLFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Abstract Feed";
	$self->{icon} = "rss-fill.svg";
	$self->{visible} = "";
	
	return $self;
}

sub is_feed { return 1; }

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
