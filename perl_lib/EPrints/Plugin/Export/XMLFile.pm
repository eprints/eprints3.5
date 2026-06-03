=head1 NAME

EPrints::Plugin::Export::XMLFile

=cut

package EPrints::Plugin::Export::XMLFile;


use EPrints::Plugin::Export;
# This virtual super-class supports Unicode output

our @ISA = qw( EPrints::Plugin::Export );


sub new
{
	my( $class, %params ) = @_;

	$params{mimetype} = exists $params{mimetype} ? $params{mimetype} : "text/xml; charset=utf-8";
	$params{suffix} = exists $params{suffix} ? $params{suffix} : ".xml";

	return $class->SUPER::new( %params );
}

sub initialise_fh
{
	my( $plugin, $fh ) = @_;

	binmode($fh, ":utf8");
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	my $xml = $self->xml_dataobj( $dataobj, %opts );
	my $r = EPrints::XML::to_string( $xml );
	EPrints::XML::dispose( $xml );

	return $r;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
