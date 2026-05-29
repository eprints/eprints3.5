######################################################################
#
# EPrints::MetaField::Counter;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Counter> - an incrementing integer

=head1 DESCRIPTION

This field represents an integer whose default value is an incrementing integer (1,2,3 ...).

=over 4

=cut

package EPrints::MetaField::Counter;

use strict;
use warnings;

use EPrints::MetaField::Int;
our @ISA = qw( EPrints::MetaField::Int );

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{sql_counter} = $EPrints::MetaField::REQUIRED;
	return %defaults;
}

sub get_default_value
{
	my( $self, $session ) = @_;

	return $session->get_database->counter_next( $self->get_property( "sql_counter" ) );
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
