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
=pod

=over 4

=item $entity = EPrints::DataObj::Entity->get( $session, $datasetid, $objectid )

Load the entity from C<$datasetid> with the ID from C<$objectid>
from the database and return it as the appropriate sub-class of an
C<EPrints::DataObj::Entity> object.

=cut
######################################################################

sub get
{
    my( $session, $datasetid, $objectid ) = @_;

    unless ( grep /$datasetid/, @{ $session->config( 'entities', 'datasets' ) } )
    {
            $session->log("ERROR: $datasetid is not a type of entity!");
    }

    return $session->get_database->get_single(
        $session->dataset( $datasetid ),
        $objectid );
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

Returns the name of the entity possibly on a particular date.

=cut
######################################################################

sub get_name
{
  my( $self, $date ) = @_;

  return $self->value( 'name' ) unless $date;
  foreach my $name ( @{$self->value( 'names' )} )
  {
        if ( ( !$name->{from} && !$name->{to} ) || ( ( !defined $name->{from} || $date ge $name->{from} ) && ( !defined $name->{to} || $date le $name->{to} ) ) )
        {
			return $name->{name};
        }
  }
}

######################################################################
=pod

=over 4

=item $boolean = $entity->has_name( $name [ $date ] )

Returns boolean for whether entity has a particular name, optionally 
on a particular date.

=cut
######################################################################

sub has_name
{
	my( $self, $name, $date ) = @_;

	my $class = $self->dataset->get_object_class;
	my $sname = $class->serialise_name( $name );

	foreach my $a_name ( @{$self->value( 'names' )} )
	{
		my  $a_sname = $class->serialise_name( $a_name->{name} );
		if ( $a_sname eq $sname )
		{
			if ( $date )
			{
				if ( ( !$a_name->{from} && !$a_name->{to} ) || ( ( !defined $a_name->{from} || $date ge $a_name->{from} ) && ( !defined $a_name->{to} || $date le $a_name->{to} ) ) )
				{
					return 1;
				}
			}
			else
			{
				return 1;
			}
		}
  	}
	return 0;
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

=item $person->generate_static

Generate the static version of the abstract/summary web page. In a
multi-language repository this will generate one version per language.

If called on eprints in the C<inbox> or C<buffer>, remove the
abstract/summary page.

=cut
######################################################################

sub generate_static
{
    my( $self ) = @_;

    $self->remove_static;

    # We is going to temporarily change the language of our session to
    # render the abstracts in each language.
    my $real_langid = $self->{session}->get_langid;

    my @langs = @{$self->{session}->get_repository->get_conf( "languages" )};
    foreach my $langid ( @langs )
    {
        $self->{session}->change_lang( $langid );
        my $full_path = $self->_htmlpath( $langid );

        my @created = EPrints::Platform::mkdir( $full_path );

        my( $page, $title, $links, $template ) = $self->render;

        my $link = $self->{session}->make_element(
            "link",
            rel=>"canonical",
            href=>$self->url_stem
        );
        $links = $self->{session}->make_doc_fragment() if( !defined $links );
        $links->appendChild( $link );
        $links->appendChild( $self->{session}->make_text( "\n" ) );

        my @plugins = $self->{session}->plugin_list(
                    type=>"Export",
                    can_accept=>"dataobj/".$self->{dataset}->confid,
                    is_advertised => 1,
                    is_visible=>"all" );
        if( scalar @plugins > 0 ) {
            foreach my $plugin_id ( @plugins )
            {
                $plugin_id =~ m/^[^:]+::(.*)$/;
                my $id = $1;
                my $plugin = $self->{session}->plugin( $plugin_id );
                my $link = $self->{session}->make_element(
                    "link",
                    rel=>"alternate",
                    href=>$plugin->dataobj_export_url( $self ),
                    type=>$plugin->param("mimetype"),
                    title=>EPrints::XML::to_string( $plugin->render_name ), );
                $links->appendChild( $link );
                $links->appendChild( $self->{session}->make_text( "\n" ) );
            }
        }
        $self->{session}->write_static_page(
            $full_path . "/index",
            {title=>$title, page=>$page, head=>$links, template=>$self->{session}->make_text($template) },
             );
    }
    $self->{session}->change_lang( $real_langid );
}


######################################################################
=pod

=item $person->remove_static

Remove the static web page or pages.

=cut
######################################################################

sub remove_static
{
    my( $self ) = @_;

    my $langid;
    foreach $langid
        ( @{$self->{session}->get_repository->get_conf( "languages" )} )
    {
        EPrints::Utils::rmtree( $self->_htmlpath( $langid ) );
    }
}

######################################################################
#
# $path = $eprint->_htmlpath( $langid )
#
# return the filesystem path in which the static files for this eprint
# are stored.
#
######################################################################

sub _htmlpath
{
    my( $self, $langid ) = @_;

    return $self->{session}->get_repository->get_conf( "htdocs_path" ).
        "/".$langid."/".$self->get_dataset_id."/".
        $self->store_path;
}


######################################################################
=pod

=item $path = $entity->store_path

Get the storage path for this entity data object.

=cut
######################################################################

sub store_path

{
    my( $self ) = @_;

    return entityid_to_path( $self->id );
}


#####################################################################
=pod

=item $path = $entity->add_name( $name, [ $commit ] )

Adds and optionally commits a name to an entities list of names.

Returns C<1> to indicate that is expected that he entity has changed.

=cut
######################################################################

sub add_name

{
    my( $self, $name, $commit ) = @_;

	my $names = $self->get_value( 'names' );
	push @$names, { name => $name };
	$self->set_value( 'names', $names );
	$self->commit( 1 ) if $commit;
	return 1;
}

#####################################################################
=pod

=item $path = $entity->add_id( $value, $type, [ $commit ] )

Adds and optionally commits an ID to an entities list of IDs.

Returns C<1> to indicate that is expected that he entity has changed.

=cut
######################################################################

sub add_id

{
    my( $self, $value, $type, $commit ) = @_;

    my $ids = $self->get_value( 'ids' );
    push @$ids, { id_value => $value, id_type => $type };
    $self->set_value( 'ids', $ids );
    $self->commit( 1 ) if $commit;
    return 1;
}

######################################################################
=pod

=item $path = EPrints::DataObj::Entity::entityid_to_path( $id )

Returns path of the storage directory based on the eprint C<$id>
provided.

=cut
######################################################################

sub entityid_to_path
{
    my( $id ) = @_;

    my $path = sprintf("%08d", $id);
    $path =~ s#(..)#/$1#g;
    substr($path,0,1) = '';

    return $path;
}

######################################################################
=pod

=item $path = EPrints::DataObj::Entity::entity_id_types( $session )

Returns an array of all possible ID types (e.g. email, url, ror, etc.)
for an entity.

=cut
######################################################################

sub entity_id_types
{
	my( $session ) = @_;

	my %id_types;
	foreach my $ent_type ( @{$session->config( 'entities', 'datasets' )} )
	{
		my $nsid = $ent_type . '_id_type';

		foreach my $id_type ( @{$session->{types}->{$nsid}} )
		{
			$id_types{$id_type} = 1;
		}
	}
	return keys %id_types;
}

######################################################################
=pod

=item ( $description, $title, $links ) = $entity->render( $preview )

Render the entity. If C<$preview> is C<true> then render a preview of
the eprint data object

The 3 returned values are references to XHTML DOM
objects. C<$description> is the public viewable description of this
eprintthat appears as the body of the abstract page. C<$title> is the
title of the abstract page for this eprint. C<$links> is any elements
which should go in the C<head> elemeny of this HTML page.

Calls L</eprint_render> to actually render the C<$eprint>, if it isn't
in the C<deleted> dataset.

=cut
######################################################################

sub render
{
    my( $self, $preview ) = @_;

    my( $dom, $title, $links, $template );

	return $self->{session}->get_repository->call(
        	$self->get_dataset_id . "_render",
            $self, $self->{session}, $preview 
		);
}

######################################################################
=pod

=item $url = $entity->get_control_url

Return the URL of the control page for this entity.

=cut
######################################################################

sub get_control_url
{
    my( $self ) = @_;

	my $dataset = $self->{session}->get_repository->get_dataset( $self->get_dataset_id );
	my $key_field_name = $dataset->key_field->get_name;

	return $self->{session}->get_repository->get_conf( "perl_url" ).
		"/users/home?screen=Entity::View&datasetid=" . $self->get_dataset_id . 
		"&entityid=" . $self->get_value( $key_field_name );
}


######################################################################
=pod

=item $serialised_name =  $entity->serialise_name( $name )

Returns serialisation of an entity's <$name> to make it quicker to
compare.

=cut
######################################################################

sub serialise_name
{
	my( $self, $name ) = @_;

	if ( !defined $name && $self->can( 'get_value' ) )
	{
		$name = $self->get_value( 'name' );
	}

	return $name;
}


######################################################################
=pod

=item $human_serialised_name = $entity->human_serialise_name( $name )

Returns human serialisation of an entity's <$name> to make it quicker 
to transfrom between some other data object input field and an entity 
data object.

=cut
######################################################################

sub human_serialise_name
{
    my( $self, $name ) = @_;

	if ( !defined $name && $self->can( 'get_value' ) ) 
	{
		$name = $self->get_value( 'name' );
	}

	if ( my $f = $self->{session}->config( 'entities', $self->get_dataset_id, 'human_serialise_name' ) )
	{
		return &$f( $name );
	}

    return $name;
}

######################################################################
=pod

=item $human_deserialised_name =  $entity->human_deserialise_name( $name )

Returns deserialisation of an entity's <$serialised_name> so this
can be saved to an entity record's name field.

=cut
######################################################################

sub human_deserialise_name
{
    my( $self, $serialised_name ) = @_;

    if ( my $f = $self->{session}->config( 'entities', $self->get_dataset_id, 'human_deserialise_name' ) )
    {
        return &$f( $serialised_name );
    }

    return $serialised_name;
}


######################################################################
=pod

=over 4

=item $entity = EPrints::DataObj::Entity::entity_with_id( $dataset, $id, [ $opts ] )

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

=item $path = EPrints::DataObj::Entity::entity_with_name( $dataset, $name, [ $opts ] )

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

######################################################################
=pod

=item $success = $dataobj->commit( [ $force ] )

Write this object to the database and reset the changed fields.

If C<$force> isn't true then it only actually modifies the database if
one or more fields have been changed.

Commit may also queue indexer jobs or log changes, depending on the
object.

=cut
######################################################################

sub commit
{
    my( $self, $force ) = @_;

    if( scalar( keys %{$self->{changed}} ) == 0 )
    {
        # don't do anything if there isn't anything to do
        return( 1 ) unless $force;
    }

    # Remove empty slots in multiple fields
    $self->tidy;

    $self->dataset->run_trigger( EPrints::Const::EP_TRIGGER_BEFORE_COMMIT,
        dataobj => $self,
        changed => $self->{changed},
    );

	$self->update_triggers();

    # Write the data to the database
    my $success = $self->{session}->get_database->update(
        $self->{dataset},
        $self->{data},
        $force ? $self->{data} : $self->{changed} );

    if( !$success )
    {
        my $db_error = $self->{session}->get_database->error;
        $self->{session}->get_repository->log(
            "Error committing ".$self->get_dataset_id.".".
            $self->get_id.": ".$db_error );
        return 0;
    }

    # Queue changes for the indexer (if indexable)
    $self->queue_changes();

    $self->dataset->run_trigger( EPrints::Const::EP_TRIGGER_AFTER_COMMIT,
        dataobj => $self,
        changed => $self->{changed},
    );

    # clear changed fields
    $self->clear_changed();

    # clear citations unless this is a citation
    $self->clear_citationcaches() if defined $self->{session}->config( "citation_caching", "enabled" ) && $self->{session}->config( "citation_caching", "enabled" ) && $self->{dataset}->confid ne "citationcache";

    return $success;
}


######################################################################
=pod

=item $entity->update_triggers

Update all the stuff that needs updating before an entity data object
is written to the database.

=cut
######################################################################

sub update_triggers
{
    my( $self ) = @_;

    $self->SUPER::update_triggers();

    if( $self->{non_volatile_change} )
    {
        $self->set_value( "lastmod", EPrints::Time::get_iso_timestamp() );
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

