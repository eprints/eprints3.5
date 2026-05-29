=head1 NAME

EPrints::Plugin::Export::XMLFiles

=cut

package EPrints::Plugin::Export::XMLFiles;

use EPrints::Plugin::Export::StaffXML;

@ISA = ( "EPrints::Plugin::Export::StaffXML" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "EP3 XML with Files Embedded";
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];

	# this module outputs the files of an eprint with
	# no regard to the security settings so should be 
	# not made public without a very good reason.
	# This should already be set by StaffXML but lets
	# not risk it.
	$self->{visible} = "staff";

	$self->{suffix} = ".xml";
	$self->{mimetype} .= '; files="base64"';
	$self->{qs} = 0.1;

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	return $self->SUPER::output_dataobj( $dataobj, %opts, embed => 1 );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
