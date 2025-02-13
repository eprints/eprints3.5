######################################################################
#
# EPrints::DataObj::Entity
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Entity> - A data object that represents a real-
world thing, such as a person, place, organisation, etc.

=head1 DESCRIPTION

UNDER DEVELOPMENT

Designed to extend L<EPrints::DataObj> to represent a real-world
thing with its own primary ID with type, alternative IDs with type 
and human-readable names.

Not designed to be instantiated directly.

=head1 CORE METADATA FIELDS

None.

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj|EPrints::DataObj#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Entity;

@ISA = ( 'EPrints::DataObj' );

use strict;

######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $dataset = EPrints::DataObj::Entity->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id { "entity" }


######################################################################
=pod

=item $system_field_info = EPrints::DataObj::Entity->get_system_field_info

Returns an array describing the system metadata of the entity dataset.

In fact, there are no fields for the entity object dataset, as it is 
an abstract dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return ();
}


######################################################################
=cut

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $path = $entity->get_primary_id

Returns the primary ID of the entity

=cut
######################################################################

sub get_primary_id
{
  my( $self ) = @_;

  return $self->value( 'id_value' );
}


######################################################################
=pod

=over 4

=item $path = $entity->get_primary_id_and_type

Returns the primary ID and type as an array reference.

=cut
######################################################################

sub get_primary_id_and_type
{
  my( $self ) = @_;

  return [ $self->value( 'id_value' ), $self->value( 'id_type' ) ];
}


######################################################################
=pod

=over 4

=item $path = $entity->get_name( [ $lang ] )

Returns the name of the entity, optional for a specific C<$lang>

=cut
######################################################################

sub get_name
{
  my( $self, $lang ) = @_;

  my $name_field = $self->{dataset}->get_field( 'name' );

  return $name_field->lang_value( $lang, $self->value( 'name' ) );
}

######################################################################
=pod

=over 4

=item $path = $entity->get_name_at( $date, $lang )

Returns the name of the entity at a particular point in time

=cut
######################################################################

sub get_name_at
{
  my( $self, $date, $lang ) = @_;

  my $value = $self->value( 'name' );
  my $name_field = $self->{dataset}->get_field( 'name' );
  foreach my $prev_name ( @{$self->value( 'previous_names' )} )
  {
        if ( $date ge $prev_name->value( 'from' ) && $date le $prev_name->value( 'from' ) )
        {
            $value = $prev_name->value( 'name' );
            $name_field = $self->{dataset}->get_field( 'previous_name' )->{name};
            last;
        }
  }

  return $name_field->lang_value( $lang, $value );
}

######################################################################
=pod

=over 4

=item $path = Eprints::DataObj::Entity::entity_with_id( $repo, $dataset, $id_value, $id_type )

Returns the name of the entity at a particular point in time

=cut
######################################################################

sub entity_with_id
{
    my( $repo, $dataset, $id_value, $id_type ) = @_;


    my $results = $dataset->search(
        filters => [
            {
                meta_fields => [qw( ids_id )],
                value => $id_value, match => "EX"
            },
            {
                meta_fields => [qw( ids_id_type )],
                value => $id_type, match => "EX"
	    }
        ]);

    for( my $r = 0; $r < $results->count; $r++ )
    {
	my $res = $results->item( $r );
	foreach my $id ( @{ $res->value( 'ids' ) } )
	{
		if ( $id_value eq $id->{id} && $id_type eq $id->{id_type} )
		{
			return $res;
		}
	}
   }
}


1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=end LICENSE

