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

=item $name = $entity->get_name( [ $date ] )

Returns the name of the entity possibly at a particular point in time.

=cut
######################################################################

sub get_name
{
  my( $self, $date ) = @_;

  return $self->value( 'name' ) unless $date;
  foreach my $name ( @{$self->value( 'names' )} )
  {
        if ( ( !$name->{from} && !$name->{to} )  || ( $name->{from} && $date ge $name->value( 'from' ) && ( !defined $name->{to} || $date le $name->{to}) ) )
        {
			return $name->{name};
        }
  }
}


######################################################################
=pod

=over 4

=item $name = $entity->get_url( [ $proto ] )

Returns the URL for the entity on EPrints.

=cut
######################################################################

sub get_url
{
	my( $self , $proto ) = @_;

    return( $self->url_stem( $proto ) );
}


######################################################################
=pod

=item $url = $entity->url_stem

Returns the URL to this entity's directory.

N.B. This includes the trailing slash, unlike the local_path method.

=cut
######################################################################

sub url_stem
{
    my( $self ) = @_;

    my $repository = $self->{session}->get_repository;
	my $dataset = $repository->get_dataset( $self->get_dataset_id );

    my $url;
    $url = $repository->get_conf( 'base_url' );
    $url .= '/id/'.$dataset->id.'/';
    $url .= $self->get_value( $dataset->key_field->get_name )+0;
    $url .= '/';

    return $url;
}

######################################################################
=pod

=item $serialised_name =  EPrints::DataObj::Entity->serialise_name( $name )

Returns serialisation of an entity's <$name> to make it quicker to
compare.

=cut
######################################################################

sub serialise_name
{
	my( $self, $name ) = @_;

	return $name;
}


######################################################################
=pod

=over 4

=item $entity = EPrints::DataObj::Entity::entity_with_id( $repo, $dataset, $id, [ $opts ] )

Returns an entity that matches the id and type provided.

Options:

	type - ID provided must also match the specified type.
	name - name should also try to match specified name.
	strict_name - boolean making name have to match specified name.

=cut
######################################################################

sub entity_with_id
{
	my( $dataset, $id, $opts ) = @_;

	my $class = $dataset->get_object_class;

	my $filters = [  
		{
			meta_fields => [qw( ids_id )],
			value => $id,
			match => "EX",
		},
	];

	if ( $opts->{type} )
	{
		push @$filters, 
		{
			meta_fields => [qw( ids_id_type )],
			value => $opts->{type},
			match => "EX",
		};
	}

	my $results = $dataset->search( filters => $filters );
	my $match = undef;
	for( my $r = 0; $r < $results->count; $r++ )
	{
		my $res = $results->item( $r );
		foreach my $a_id ( @{ $res->value( 'ids' ) } )
		{
			# If ID matches and type matches when specified
			if ( $id eq $a_id->{id} && ( !$opts->{type} || $opts->{type} eq $a_id->{id_type} ) )
			{
				# Return result unless trying to also match name
				return $res unless $opts->{name};

				# Unless must also match name store first result with matching ID.
				$match = $res if !$match && !$opts->{strict_name};

				foreach my $name ( @{ $res->value( 'names' ) } )
				{
					# If result also matches name then return it.
					if ( $class->serialise_name( $name->{name} ) eq $class->serialise_name( $opts->{name} ) )
					{
						return $res;
					}
				}
			}
		}
	}

	# May have a suitable match may just return undef
	return $match;
}


######################################################################
=pod

=over 4

=item $path = Eprints::DataObj::Entity::entity_with_name( $dataset, $name, [ $opts ] )

Returns the name of the entity at a particular point in time.

Options:

        no_id - boolean specifying entity must currently have no ID.

=cut
######################################################################

sub entity_with_name
{
	my( $dataset, $name, $opts ) = @_;

	my $class = $dataset->get_object_class;

	my $name_results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( name )],
				value => $name,
				match => "EX",
			},
		],
		custom_order => "-lastmod",
	);

	# If the result must not have an ID check each result and only return one without an ID set.
	if ( $opts->{no_id} )
	{
		for ( my $r = 0; $r < $name_results->count; $r++ )
		{
			my $res = $name_results->item( $r );
			return $res unless $res->get_value( 'id_value' );
		}
	}
	else
	{
		# If there is any results that match the name then return the first one.
		return $name_results->item( 0 ) if $name_results->count > 0;
	}

	# Search for name across all names for entity.
	my $names_results = $dataset->search(
		filters => [
			{
				meta_fields => [qw( names_name )],
				value => $name,
				match => "EX",
			},
		],
		custom_order => "-lastmod",
	);

	my $latest_entity = undef;
	my $latest_date = 0;
	for( my $r = 0; $r < $names_results->count; $r++ )
	{
		my $res = $names_results->item( $r );
		# Iterate over all names for the entity
		foreach my $a_name ( @{ $res->value( 'names' ) } )
		{
			# If a name for the entity matches that provided
			if ( $class->serialise_name( $a_name->{name} ) eq $class->serialise_name( $name ) )
			{
				# If the result has and ID set and an entity without and ID is wanted, skip it.
				next if $opts->{no_id} && $res->value( 'id_value' );

				# If the name that has matched has no end date then return result
				if ( !$a_name->{to} )
				{
					return $res;
				}
				# If the name that has matched has a later end date then current latest entity then update the latest entity.
				elsif ( $a_name->{to} gt $latest_date )
				{
					$latest_date = $name->{to};
					$latest_entity = $res;
				}
			}
		}
	}

	# Return the latest entity if one has been found, otherwise undef is returned.
	return $latest_entity;
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

