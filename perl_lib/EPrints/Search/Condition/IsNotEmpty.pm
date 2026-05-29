######################################################################
#
# EPrints::Search::Condition::IsNotEmpty
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::IsNotEmpty> - "IsNotEmpty" search 
condition.

=head1 DESCRIPTION

Matches items where the field is not empty.  Only really applicable 
for textual fields.  As != '' is equivalent to != 0 for numeric 
fields, where 0 may not necessarily imply empty (e.g. 
item_issues_count = 0, means there are no issues for that item 
rather than the field really being empty.

=cut

package EPrints::Search::Condition::IsNotEmpty;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
	my( $class, @params ) = @_;

	return $class->SUPER::new( "is_not_empty", @params );
}

sub logic
{
	my( $self, %opts ) = @_;

	my $prefix = $opts{prefix};
	$prefix = "" if !defined $prefix;
	if( !$self->{field}->get_property( "multiple" ) )
	{
		$prefix = "";
	}

	my $db = $opts{session}->get_database;
	my $table = $prefix . $self->table;

	my @sql_and = ();
	foreach my $col_name ( $self->{field}->get_sql_names )
	{
		push @sql_and,
			$db->quote_identifier( $table, $col_name )." != ''";
	}
	return "( ".join( " OR ", @sql_and ).")";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
