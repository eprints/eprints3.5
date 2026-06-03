######################################################################
#
# EPrints::Search::Condition::True
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::True> - "True" search condition

=head1 DESCRIPTION

Matches all items.

=cut

package EPrints::Search::Condition::True;

use EPrints::Search::Condition;

@ISA = qw( EPrints::Search::Condition );

use strict;

sub new
{
	my( $class ) = @_;

	return bless { op=>"TRUE" }, $class;
}

sub logic
{
	return "1=1";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
