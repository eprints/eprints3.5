######################################################################
#
# EPrints::MetaField::Arclanguage
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Arclanguage> - no description

=head1 DESCRIPTION

I<To be written>

=over 4

=cut

# type_set

package EPrints::MetaField::Arclanguage;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Set );
}

use EPrints::MetaField::Set;

sub tags
{
	my( $self, $session ) = @_;

	return @{$session->config( "languages" )};
}

sub get_unsorted_values
{
	my( $self, $session, $dataset, %opts ) = @_;

	return @{$session->config( "languages" )};
}

sub render_option
{
	my( $self, $session, $value ) = @_;

	return $session->render_type_name( 'languages', $value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	delete $defaults{options}; # inherited but unwanted
	return %defaults;
}



######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
