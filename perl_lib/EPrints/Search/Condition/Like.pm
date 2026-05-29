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

B<EPrints::Search::Condition::Like> - "Like" search condition

=head1 DESCRIPTION

Matches items that are the same ignoring case

=cut

package EPrints::Search::Condition::Like;

use EPrints::Search::Condition::Comparison;

@ISA = qw( EPrints::Search::Condition::Comparison );

use strict;

sub new
{
        my( $class, @params ) = @_;

        my $self = {};
        $self->{op} = "like";
        $self->{dataset} = shift @params;
        $self->{field} = shift @params;
        $self->{params} = \@params;

        return bless $self, $class;
}


sub logic
{
        my( $self, %opts ) = @_;

        my $prefix = $opts{prefix};
        $prefix = "" if !defined $prefix;

        my $db = $opts{session}->get_database;
        my $table = $prefix . $self->table;
        my $sql_name = $self->{field}->get_sql_name;

        return sprintf( "%s ".$db->sql_LIKE." '%s'",
                $db->quote_identifier( $table, $sql_name ),
                EPrints::Database::prep_like_value( $self->{params}->[0] ) );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
