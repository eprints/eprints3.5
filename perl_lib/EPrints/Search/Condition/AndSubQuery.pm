######################################################################
#
# EPrints::Search::Condition::AndSubQuery
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::AndSubQuery> - AndSubQuery

=head1 DESCRIPTION

SubQuery is used internally by the search optimisation to make OR queries on the same table more efficient.

=cut

package EPrints::Search::Condition::AndSubQuery;

use EPrints::Search::Condition::SubQuery;

@ISA = qw( EPrints::Search::Condition::SubQuery );

use strict;

sub joins
{
	my( $self, %opts ) = @_;

	my $db = $opts{session}->get_database;
	my $dataset = $opts{dataset};

	my $alias = "and_".Scalar::Util::refaddr( $self );
	my $key_name = $dataset->get_key_field->get_sql_name;

	# operations on the main table are applied directly in logic()
	my @intersects;
	foreach my $sub_op ( @{$self->{sub_ops}} )
	{
		push @intersects, $sub_op->sql( %opts, key_alias => $key_name );
	}

	my $i = 0;
	return map { {
		type => "inner",
		subquery => "($_)",
		alias => $alias . "_" . $i++,
		key => $key_name,
	} } @intersects;
}

sub logic
{
	return ();
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
