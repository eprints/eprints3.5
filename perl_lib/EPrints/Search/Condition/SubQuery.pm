######################################################################
#
# EPrints::Search::Condition::SubQuery
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Search::Condition::SubQuery> - SubQuery

=head1 DESCRIPTION

SubQuery is used internally by the search optimisation to make OR queries on the same table more efficient.

=cut

package EPrints::Search::Condition::SubQuery;

use EPrints::Search::Condition;
use Scalar::Util;

@ISA = qw( EPrints::Search::Condition );

use strict;

sub new
{
	my( $class, @params ) = @_;

	my $self = bless {
			op => $class,
			dataset => shift(@params),
			sub_ops => \@params
		}, $class;
	$self->{op} =~ s/^.*:://;

	return $self;
}

sub joins
{
	my( $self, %opts ) = @_;

	# Stop sub_ops from using their own prefixes (InSubject)
	$opts{prefix} = "" if !defined $opts{prefix};

	return $self->{sub_ops}->[0]->joins( %opts );
}

sub logic
{
	my( $self, %opts ) = @_;

	# Stop sub_ops from using their own prefixes (InSubject)
	$opts{prefix} = "" if !defined $opts{prefix};

	my @logic = map { $_->logic( %opts ) } @{$self->{sub_ops}};

	return @logic ? "(".join(" OR ", @logic).")" : ();
}

sub alias
{
	my( $self ) = @_;

	my $alias = lc(ref($self));
	$alias =~ s/^.*:://;
	$alias .= "_".Scalar::Util::refaddr($self);

	return $alias;
}

sub key_alias
{
	my( $self, %opts ) = @_;

	my $dataset = $opts{dataset};

	return $dataset->get_key_field->get_sql_name . "_" . Scalar::Util::refaddr($self);
}

sub table
{
	my( $self ) = @_;

	return $self->{sub_ops}->[0]->table;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
