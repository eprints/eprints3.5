=head1 NAME

EPrints::Plugin::Export::XML

=cut

package EPrints::Plugin::Export::StaffXML;

use EPrints::Plugin::Export::XML;

@ISA = ( "EPrints::Plugin::Export::XML" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "EP3 XML (Staff)";

	# this module outputs fields that have export_as_xml 
	# set to 0, which should not appear in public export.
	$self->{visible} = "staff";
	
	$self->{qs} = 0.4;

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	return $self->SUPER::output_dataobj( $dataobj, %opts, revision_generation => 1 );
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
