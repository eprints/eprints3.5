=head1 NAME

EPrints::Plugin::Export::Text

=cut

package EPrints::Plugin::Export::Text;

use EPrints::Plugin::Export::TextFile;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "ASCII Citation";
	$self->{accept} = [ 'dataobj/eprint', 'dataobj/organisation', 'dataobj/person','list/eprint', 'list/organisation', 'list/person' ];
	$self->{visible} = "all";
	
	return $self;
}


sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $cite = $dataobj->render_citation;

	return EPrints::Utils::tree_to_utf8( $cite )."\n\n";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
