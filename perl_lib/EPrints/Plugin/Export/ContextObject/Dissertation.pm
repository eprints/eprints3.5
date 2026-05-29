=head1 NAME

EPrints::Plugin::Export::ContextObject::Dissertation

=cut

package EPrints::Plugin::Export::ContextObject::Dissertation;

use EPrints::Plugin::Export::ContextObject;

@ISA = ( "EPrints::Plugin::Export::ContextObject" );

use strict;

our %MAPPING = qw(
	title	title
	pages	tpages
	date	date
	institution	inst
	thesis_type	degree
);

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "OpenURL Dissertation";
	$self->{accept} = [ 'dataobj/eprint' ];
	$self->{visible} = "";

	return $self;
}

sub xml_dataobj
{
	my( $plugin, $dataobj, %opts ) = @_;

	return $plugin->xml_entity_dataobj( $dataobj, %opts,
		mapping => \%MAPPING,
		prefix => "dis",
		namespace => "info:ofi/fmt:xml:xsd:dissertation",
		schemaLocation => "info:ofi/fmt:xml:xsd:dissertation http://www.openurl.info/registry/docs/info:ofi/fmt:xml:xsd:dissertation",
	);
}

sub kev_dataobj
{
	my( $plugin, $dataobj, $ctx ) = @_;

	my $data = $plugin->convert_dataobj( $dataobj, mapping => \%MAPPING );

	# Can only include the first author in KEV
	my $first_author;
	for(my $i = 0; $i < @$data; ++$i)
	{
		if( $data->[$i]->[0] eq "author" )
		{
			my $e = splice @$data, $i, 1;
			--$i;
			$first_author ||= $e->[1];
		}
	}
	$first_author ||= {};
	# Sorry, this is a very compact way of expanding out the sub-arrays
	@$data = (%$first_author, map { @$_ } @$data);

	$ctx->dissertation( @$data );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
