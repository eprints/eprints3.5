######################################################################
#
# EPrints::Search::Condition::IsNotNull
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::IsNotNull> - "IsNotNull" search 
condition.

=head1 DESCRIPTION

Matches items where the field is not null.

=cut

package EPrints::Search::Condition::IsNotNull;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
	my( $class, @params ) = @_;

	return $class->SUPER::new( "is_not_null", @params );
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
			$db->quote_identifier( $table, $col_name )." IS NOT NULL";
	}
	return "( ".join( " OR ", @sql_and ).")";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
