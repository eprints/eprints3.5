=head1 NAME

EPrints::Plugin::Import::XML

=cut

package EPrints::Plugin::Import::XML;

use strict;

use EPrints::Plugin::Import::DefaultXML;

our @ISA = qw/ EPrints::Plugin::Import::DefaultXML /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{name} = "EPrints XML";
	$self->{visible} = "all";
	$self->{produce} = [ 'list/*', 'dataobj/*' ];
	$self->{accept} = ["application/vnd.eprints.data+xml; charset=utf-8", "sword:http://eprints.org/ep2/data/2.0"];

	return $self;
}

sub top_level_tag
{
	my( $plugin, $dataset ) = @_;

	return $dataset->confid."s";
}

sub unknown_start_element
{
	my( $self, $found, $expected ) = @_;

	if( $found eq "eprintsdata" ) 
	{
		$self->warning( "You appear to be attempting to import an EPrints 2 XML file!\nThis importer only handles v3 files. Use the migration toolkit to convert!\n" );
	}
	$self->SUPER::unknown_start_element( @_[1..$#_] );
}

sub xml_to_epdata
{
	my( $plugin, $dataset, $xml, %opts ) = @_;

	my $epdata = $dataset->get_object_class->xml_to_epdata(
		$plugin->{session},
		$xml,
		%opts,
		Handler => $plugin->{Handler} );

	return $epdata;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
