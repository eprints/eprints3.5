=head1 NAME

EPrints::Plugin::Export::CSV

=head1 DESCRIPTION

Subclass of MultilineCSV but exports only fields set "export_as_xml" and is publicly visible.

=cut

package EPrints::Plugin::Export::CSV;

use EPrints::Plugin::Export::MultilineCSV;

@ISA = ( "EPrints::Plugin::Export::MultilineCSV" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Multiline CSV";
	$self->{visible} = "all";
	
	return $self;
}

sub fields
{
	my( $self, $dataset ) = @_;

	# skip compound, subobjects
	return grep {
			$_->property("export_as_xml") &&
			!$_->is_virtual
		} 
		$dataset->fields;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
