######################################################################
#
# EPrints::Search::Condition::NameMatch
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::NameMatch> - "NameMatch" search condition

=head1 DESCRIPTION

Matches items with a matching name.

=cut

package EPrints::Search::Condition::NameMatch;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
	my( $class, @params ) = @_;

	return $class->SUPER::new( "=", @params );
}

sub extra_describe_bits
{
	my( $self ) = @_;

	return '"'.$self->{params}->[0]->{family}.'"', 
		'"'.$self->{params}->[0]->{given}.'"';
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
