######################################################################
#
# EPrints::MetaField::Idci;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Idci> - a case-insensitive identifier string

=head1 DESCRIPTION

Use Idci fields whenever you are storing textual data that needs to be matched exactly but case insensivity is required (e.g. usernames and email addresses).

Characters that are not valid XML 1.0 code-points will be replaced with the Unicode replacement character.

=over 4

=cut

package EPrints::MetaField::Idci;

use EPrints::MetaField::Id;

@ISA = qw( EPrints::MetaField::Id );

use strict;

sub get_search_conditions
{
        my( $self, $session, $dataset, $search_value, $match, $merge,
                $search_mode ) = @_;

        if( $match eq "SET" )
        {
                return EPrints::Search::Condition->new(
                                "is_not_null",
                                $dataset,
                                $self );
        }

        if( $match eq "EX" )
        {
                if( !EPrints::Utils::is_set( $search_value ) )
                {
                        return EPrints::Search::Condition->new(
                                        'is_null',
                                        $dataset,
                                        $self );
                }

                return EPrints::Search::Condition->new(
                                'like',
                                $dataset,
                                $self,
                                $search_value );
        }

        return $self->get_search_conditions_not_ex(
                        $session,
                        $dataset,
                        $search_value,
                        $match,
                        $merge,
                        $search_mode );
}


######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
