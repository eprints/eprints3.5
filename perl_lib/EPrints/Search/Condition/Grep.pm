######################################################################
#
# EPrints::Search::Condition::Grep
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::Grep> - "Grep" search condition

=head1 DESCRIPTION

Filter using a grep table

=cut

package EPrints::Search::Condition::Grep;

use EPrints::Search::Condition::Index;

@ISA = qw( EPrints::Search::Condition::Index );

use strict;

sub new
{
	my( $class, @params ) = @_;

	my $self = {};
	$self->{op} = "grep";
	$self->{dataset} = shift @params;
	$self->{field} = shift @params;
	$self->{params} = \@params;

	return bless $self, $class;
}

sub table
{
	my( $self ) = @_;

	return undef if( !defined $self->{field} );

	return $self->{field}->{dataset}->get_sql_grep_table_name;
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
	my $sql_name = $self->{field}->get_sql_name;

	my @logic;
	foreach my $cond (@{$self->{params}})
	{
		push @logic, sprintf("%s LIKE %s",
			$db->quote_identifier( $table, "grepstring" ),
			$db->quote_value( $cond ) );
	}

	return sprintf( "%s=%s AND (%s)",
		$db->quote_identifier( $table, "fieldname" ),
		$db->quote_value( $sql_name ),
		join(" OR ", @logic));
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
