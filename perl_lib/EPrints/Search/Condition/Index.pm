######################################################################
#
# EPrints::Search::Condition::Index
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::Index> - "Index" search condition

=head1 DESCRIPTION

Matches items with a matching search index value.

=cut

package EPrints::Search::Condition::Index;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
	my( $class, @params ) = @_;

	return $class->SUPER::new( "index", @params );
}

sub table
{
	my( $self ) = @_;

	return undef if( !defined $self->{field} );

	return $self->{field}->{dataset}->get_sql_rindex_table_name;
}

sub joins
{
	my( $self, %opts ) = @_;

	my $prefix = $opts{prefix};
	$prefix = "" if !defined $prefix;

	my $field = $self->{field};
	if( !$field->{dataset}->indexable )
	{
		EPrints->abort( "Can not perform index query on non-indexed dataset for ".$field->{dataset}->base_id.".".$field->name );
	}

	my $db = $opts{session}->get_database;
	my $table = $self->table;
	my $key_field = $self->dataset->get_key_field;

	my( $join ) = $self->SUPER::joins( %opts );

	# joined via an intermediate table
	if( defined $join )
	{
		if( defined($join->{table}) && $join->{table} eq $table )
		{
			return $join;
		}
		# similar to a multiple table match in comparison
		return (
			$join,
			{
				type => "inner",
				table => $table,
				alias => "$prefix$table",
				logic => $db->quote_identifier( $join->{alias}, $key_field->get_sql_name )."=".$db->quote_identifier( "$prefix$table", $key_field->get_sql_name ),
			}
		);
	}
	else
	{
		# include this table and link it to the main table in logic
		return {
			type => "inner",
			table => $table,
			alias => "$prefix$table",
			logic => $db->quote_identifier( $opts{dataset}->get_sql_table_name, $key_field->get_sql_name )."=".$db->quote_identifier( "$prefix$table", $key_field->get_sql_name ),
			key => $key_field->get_sql_name,
		};
	}
}

sub logic
{
	my( $self, %opts ) = @_;

	my $prefix = $opts{prefix};
	$prefix = "" if !defined $prefix;

	my $db = $opts{session}->get_database;
	my $table = $prefix . $self->table;
	my $sql_name = $self->{field}->get_sql_name;

	return sprintf( "%s=%s AND %s=%s",
		$db->quote_identifier( $table, "field" ),
		$db->quote_value( $sql_name ),
		$db->quote_identifier( $table, "word" ),
		$db->quote_value( $self->{params}->[0] ) );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
