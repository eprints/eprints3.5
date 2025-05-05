$c->{render_contributions_contributor} = sub {

	my( $session, $field, $value, $alllangs, $nolink, $object ) = @_;

	$session = $object->repository unless $session->can("make_doc_fragment");

	my $frag = $session->make_doc_fragment;

	my $dataset = $session->get_dataset( $value->{datasetid} );
	my $entity = $dataset->dataobj( $value->{entityid} );
	
	$frag->appendChild( $entity->render_citation_link( 'default' ) ) if defined $entity;

	return $frag;
};

$c->{contributions_fromform} = sub {
	my ( $value, $session, $object, $basename ) = @_;

	my $type = $session->param($basename . "_type") ? $session->param($basename . "_type") : undef;
	my $datasetid = $session->param($basename . "_contributor_datasetid") ? $session->param($basename . "_contributor_datasetid") : undef;
	my $entityid = $session->param($basename . "_contributor_entityid") ? $session->param($basename . "_contributor_entityid") : undef;
	my $id_value = $session->param($basename . "_contributor_entity_id_value");
	my $id_type = $session->param($basename . "_contributor_entity_id_type");
	my $name = $session->param($basename . "_contributor_entity_name");
	my $deserialised_name = $name;
	if ( $datasetid && $session->config( 'entities', $datasetid, 'human_deserialise_name' ) )
	{
			my $f = $session->config( 'entities', $datasetid, 'human_deserialise_name' );
			$deserialised_name = &$f( $name );
	}

	if ( $datasetid && $entityid )
	{
		my $ds = $session->dataset( $datasetid );
		my $entity = $ds->dataobj( $entityid );
		my $entity_from_id = EPrints::DataObj::Entity::entity_with_id( $ds, $id_value, { type => $id_type } );
		if ( defined $entity && defined $entity_from_id )
		{
			if ( $entity->id eq $entity_from_id->id )
			{
				unless ( $entity->has_name( $deserialised_name ) )
				{
					my $entity_names = $entity->get_values( 'names' );
					push @$entity_names, $deserialised_name;
					$entity->set_value( 'names', $entity_names );
					$entity->commit( 1 );
				}
			}
			else
			{
				unless ( $entity_from_id->has_name( $deserialised_name ) )
				{
					my $entity_names = $entity_from_id->get_values( 'names' );
					push @$entity_names, $deserialised_name;
					$entity_from_id->set_value( 'names', $entity_names );
					$entity_from_id->commit( 1 );
				}
				$entityid = $entity_from_id->id;

			}
		}
		elsif ( defined $entity )
		{
			my $changed = 0;
			unless ( $entity->has_name( $deserialised_name ) )
			{
				my $entity_names = $entity->get_values( 'names' );
				push @$entity_names, $deserialised_name;
				$entity->set_value( 'names', $entity_names );
				$changed = 1;
			}
			if ( $id_value && $id_type )
			{
				my $entity_ids = $entity->get_values( 'ids' );
				push @$entity_ids, { id => $id_value, id_type => $id_type };
				$entity->set_value( 'id', $entity_ids );
				$changed = 1;
			}
					$entity->commit( 1 ) if $changed;
		}
		elsif ( defined $entity_from_id )
		{
			unless ( $entity_from_id->has_name( $deserialised_name ) )
			{
				my $entity_names = $entity_from_id->get_values( 'names' );
				push @$entity_names, $deserialised_name;
				$entity_from_id->set_value( 'names', $entity_names );
				$entity_from_id->commit( 1 );
			}
			$entityid = $entity_from_id->id;
		}
		else
		{
			my $entity_data = { names => [ { name => $deserialised_name } ], ids => [ { id => $id_value, id_type => $id_type } ] };
			my $entity = $ds->create_dataobj( $entity_data );
			$entity->commit( 1 );
			$entityid = $entity->id;
		}
	}
	elsif ( $datasetid )
	{
		my $ds = $session->dataset( $datasetid );
		my $entity_from_id = EPrints::DataObj::Entity::entity_with_id( $ds, $id_value, { type => $id_type } );
		if ( defined $entity_from_id )
		{
			$entityid = $entity_from_id->id;
		}
		elsif ( $name )
		{
			my $entity_data = { names => [ { name => $deserialised_name } ], ids => [ { id => $id_value, id_type => $id_type } ] };
			my $entity = $ds->create_dataobj( $entity_data );
			$entity->commit( 1 );
			$entityid = $entity->id;
		}
	}
	unless ( $entityid )
	{
		return {};
	}

	my $new_value = {
		type => $type,
		contributor => {
			datasetid => $datasetid,
			entityid => $entityid,
			name => $deserialised_name,
			id_value => $id_value,
			id_type => $id_type,
		},
	};

	return $new_value;
};

$c->{render_input_contributions} = sub {
	my( $self, $session, $value, $dataset, $staff, $hidden_fields, $obj, $basename, $one_field_component ) = @_;

	my $titles = [];
	my $rows = [];

	my $col_titles = $self->get_input_col_titles( $session, $staff );

	if( defined $col_titles )
	{
		if( $self->get_property( "multiple" ) && $self->{input_ordered})
		{
			push @$titles, {
				column_index => 0,
				empty_column => 1,
			};
		}

		my @input_ids = $self->get_basic_input_ids( $session, $basename, $staff );

		my $x = 0;

		foreach my $col_title ( @{$col_titles} )
		{
			push @$titles, {
				column_index => $x,
				title => $col_title,
				id => $input_ids[$x],
			};

			$x++;
		}
	}

	my $datasetid = $dataset->id;
	my $datasets = {};
	foreach my $dsid ( @{$session->config( 'entities', 'datasets' )} )
	{
		$datasets->{$dsid} = $session->dataset( $dsid );
	}

	my $elements = $self->get_input_elements( $session, $value, $staff, $obj, $basename, $one_field_component );
	my $buttons = $session->make_doc_fragment;
	my $y = 0;

	foreach my $row ( @{$elements} )
	{
		my $x = 0;

		my $row_info = {
			row_index => $y,
			cells => [],
		};

		if ( ref( $row ) eq "ARRAY" )
		{

			foreach my $item ( @{$row} )
			{
				next if $x == 3;
				my $cell_info = {
					column_index => $x,
					attrs => [],
				};

				foreach my $prop ( keys %{$item} )
				{
					next if( $prop eq "el" );

					push @{ $cell_info->{attrs} }, {
						name => $prop,
						value => $item->{$prop},
					};
				}

				if( defined $item->{el} )
				{
					$cell_info->{item} = $item->{el};
				}

				push @{ $row_info->{cells} }, $cell_info;
				$x++;
			}
			push @$rows, $row_info;
		}
		else
		{
			my %opts = ( id=>$basename."_buttons" );
			foreach my $prop ( keys %{$row} )
			{
				next if( $prop eq "el" );
				$opts{$prop} = $row->{$prop};
			}
			$buttons = $session->make_element( "div", %opts );
			$buttons->appendChild( $row->{el} );
		}
		$y++;
	}

	my @eitf_options = ();
	my $eitf_labels = {};
	foreach my $ent_type ( @{$session->config( 'entities', 'datasets' )} )
	{
		my $nsid = $ent_type . '_id_type';
		foreach my $id_type ( @{$session->{types}->{$nsid}} )
		{
			my $idt_label = $session->phrase( $nsid . '_typename_' . $id_type );
			unless ( $eitf_labels->{$id_type} )
			{
				push @eitf_options, $id_type;
				$eitf_labels->{$id_type} = $idt_label;
		   }
		}
	}
	unshift @eitf_options, '';
	$eitf_labels->{''} = $session->phrase( 'lib/metafield:unspecified' );

	$y = 0;

	foreach my $row ( @$rows )
	{
		next unless ref( $row ) eq "HASH";
		my $yp1 = $y+1;
		my $entity_field = $session->make_element( "div", ( id=>$basename."_cell_3_".$yp1 ) );
		my $ef_baseclass = $basename . "_contributor_entity";
		my $ef_basename = $basename . "_" . $yp1 . "_contributor_entity";
		my $enf_name = $ef_basename . "_name";
		my $enf_value = undef;
		my $eivf_name = $ef_basename . "_id_value";
		my $eivf_value = undef;
		my $eitf_name = $ef_basename . "_id_type";
		my $eitf_value = undef;
		my $eu_name = $ef_basename . "_unset";
		my $es_name = $ef_basename . "_span";
		my $eif_name = $ef_basename . "id";
		my $contributor_datasetid = $value->[$y]->{contributor}->{datasetid};
		my $contributor_entityid = $value->[$y]->{contributor}->{entityid};
		if ( $contributor_datasetid && $contributor_entityid )
		{
			my $contributor = $datasets->{$contributor_datasetid}->dataobj( $contributor_entityid );
			$enf_value = $contributor->human_serialise_name;
			$eivf_value = $contributor->get_value( 'id_value' );
			$eitf_value = $contributor->get_value( 'id_type' );
		}

		my $enf_input = $session->render_noenter_input_field(
			class => "ep_form_text ep_${datasetid}_${ef_baseclass}_name eptype_${datasetid}_text",
			name => $enf_name,
			id => $enf_name,
			value => $enf_value,
			size => 25,
			autocomplete => "off",
			'aria-labelledby' => $self->get_labelledby( $enf_name ),
			'aria-describedby' => $self->get_describedby( $enf_name, $one_field_component ),
		);
		$entity_field->appendChild( $enf_input );
		my $eivf_input = $session->render_noenter_input_field(
			class => "ep_form_text ep_${datasetid}_${ef_baseclass}_id_value eptype_${datasetid}_text",
			name => $eivf_name,
			id => $eivf_name,
			value => $eivf_value,
			size => 25,
			autocomplete => "off",
			'aria-labelledby' => $self->get_labelledby( $eivf_name ),
			'aria-describedby' => $self->get_describedby( $eivf_name, $one_field_component ),
		);
		$entity_field->appendChild( $eivf_input );
		my $eitf_input = $session->render_option_list(
			class => "ep_form_text ep_${datasetid}_${ef_baseclass}_id_type eptype_${datasetid}_select",
			name => $eitf_name,
			id => $eitf_name,
			default => $eitf_value,
			values => \@eitf_options,
			labels => $eitf_labels,
			'aria-labelledby' => $self->get_labelledby( $eitf_name ),
			'aria-describedby' => $self->get_describedby( $eitf_name, $one_field_component ),
		);
		$entity_field->appendChild( $eitf_input );
		my $entity_span = $session->make_element( 'span', id => $es_name, class => "ep_entity_span" );

		if ( $contributor_entityid )
		{
			my $entity = $datasets->{$contributor_datasetid}->dataobj( $contributor_entityid );
			my $entity_link = $session->make_element( 'a', href => $entity->get_url, target => '_blank' );
			$entity_link->appendChild( $session->html_phrase( 'eprint_fieldopt_contributions_contributor_datasetid_' . $contributor_datasetid ) ); 
			$entity_link->appendChild( $session->make_text( ' ' . $contributor_entityid ) );
			$entity_span->appendChild( $entity_link );
		}
		$entity_field->appendChild( $entity_span );
		my $eu_button = $session->make_element( 'a', href => '#', id => $eu_name, value => $session->phrase( 'contributions:unset' ), onclick => "unset_entity( event, '${basename}_${yp1}_' )" );
		my $eu_button_img = $session->make_element( 'img', src => $session->config( 'rel_path' ) . '/style/images/cross.png', alt => $session->phrase( 'contributions:unset' ) );
        $eu_button->appendChild( $eu_button_img );
        $entity_field->appendChild( $eu_button );
        my $entityid_input = $session->xhtml->input_field( $eif_name, $contributor_entityid, type => 'hidden', id => $eif_name );
        $entity_field->appendChild( $entityid_input );

		my $entity_cell =  {
			item => $entity_field,
			column_index => 3,
			attrs => [],
		};
		push @{ $row->{cells} }, $entity_cell;
		$y++;
	}

	my $extra_params = URI->new( 'http:' );
	$extra_params->query( $self->{input_lookup_params} );
	my %defaults = ( 'type' => '', contributor_datasetid => '', contributor_entity_id_type => '' );
	my @params = (
		$extra_params->query_form,
		field => $self->name
	);
	if( defined $obj )
	{
		push @params, dataobj => $obj->id;
	}
	if( defined $self->{dataset} )
	{
		push @params, dataset => $datasetid;
		my $contrib_fields = $self->{dataset}->get_field( 'contributions' )->get_property( 'fields' );
		$defaults{type} = $contrib_fields->[0]->{default_value} if defined $contrib_fields->[0]->{default_value};
		$defaults{contributor_datasetid} = $contrib_fields->[1]->{fields}->[0]->{default_value} if defined $contrib_fields->[1]->{fields}->[0]->{default_value};
		$defaults{contributor_entity_id_type} = $contrib_fields->[1]->{fields}->[2]->{default_value} if defined $contrib_fields->[1]->{fields}->[2]->{default_value};
	}
	$extra_params->query_form( @params );
	$extra_params = "&" . $extra_params->query;

	my $componentid = substr($basename, 0, length($basename)-length($self->{name})-1);
	my $url = EPrints::Utils::js_string( $self->{input_lookup_url} );
	my $params = EPrints::Utils::js_string( $extra_params );

	my $javascript = $session->make_javascript( <<EOJ );
new Metafield ('$componentid', '$self->{name}', {
	input_lookup_url: $url,
	input_lookup_params: $params
});

function unset_entity( e, base_id ) {
	e.preventDefault();
	const subfields = [ 'type', 'contributor_datasetid', 'contributor_entity_name', 'contributor_entity_id_value', 'contributor_entity_id_type', 'contributor_entityid', 'contributor_entity_span' ];
	const subfield_values = [ '$defaults{type}', '$defaults{contributor_datasetid}', '', '', '$defaults{contributor_entity_id_type}', '', '' ];
	for (let sf = 0; sf < subfields.length; sf++) {
		var entity_field = document.getElementById(base_id + subfields[sf]);
		if ( entity_field.tagName == 'SPAN' )
		{
			entity_field.innerHTML = subfield_values[sf];
		}
		else
		{
			entity_field.value = subfield_values[sf];
		}
	}
}

EOJ

	return $self->repository->template_phrase( "view:MetaField/render_input_field_actual", { item => {
		basename => $basename,
		has_col_titles => !!$col_titles,
		titles => $titles,
		rows => $rows,
		buttons => $buttons,
		javascript => $javascript,
	} } );


	my $frag = $self->render_input_field_actual(
			$session,
			$value,
			$dataset,
			$staff,
			$hidden_fields,
			$obj,
			$basename,
			$one_field_component );

	return $frag;
};


$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_;
	my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	my $workflow = EPrints::Workflow->new( $repo, 'default', ( item => $eprint ) );
	my $primary_id_types = $repo->config( 'entities', 'primary_id_types' );
	my $all_contrib_fields =  $repo->config( 'entities', 'field_contribution_types', 'eprint' );

	
	if ( $workflow->{field_stages}->{contributions} )
	{
		my $dataset = $repo->dataset( 'eprint' );
		my $all_contrib_maps = $repo->config( 'entities', 'field_contribution_maps', 'eprint' );

		my $entity_datasets = {};
		foreach my $dsid ( @{$repo->config( 'entities', 'datasets' )} )
		{
			$entity_datasets->{$dsid} = $repo->dataset( $dsid );
		}

		my $contributions = $eprint->get_value( "contributions" );
		my $changes = {};


		foreach my $entity_type ( keys %$all_contrib_fields )
		{		
			foreach my $field_name ( keys %{$all_contrib_fields->{$entity_type}} )
			{
				my $field = $dataset->field( $field_name );
				if ( $field->get_property( 'multiple' ) )
				{
					$changes->{$field_name} = [];
				}
				else
				{
					$changes->{$field_name} = undef;
				}
			}
		}

		foreach my $contribution ( @$contributions )
		{
			my $entity_contrib_fields = $all_contrib_fields->{$contribution->{contributor}->{datasetid}};
			my $entity_contrib_maps = $all_contrib_maps->{$contribution->{contributor}->{datasetid}};
			my $entity = $entity_datasets->{$contribution->{contributor}->{datasetid}}->dataobj( $contribution->{contributor}->{entityid} );

			foreach my $field_name ( keys %$entity_contrib_fields )
			{
				if ( $entity_contrib_fields->{$field_name} eq $contribution->{type} )
				{
					my $field = $dataset->field( $field_name );
					my $field_value;
					if ( $field->has_property( 'fields_cache' ) )
					{
						next unless $entity_contrib_maps->{$field_name};
						my $subfields = $field->get_property( 'fields_cache' );
						foreach my $subfield ( @$subfields )
						{
							if ( my $map = $entity_contrib_maps->{$field_name}->{$subfield->{sub_name}} )
							{
								my @map_bits = split( ':', $map );
								if ( scalar @map_bits == 1 )
								{
									$field_value->{$subfield->{sub_name}} = $contribution->{$map_bits[0]};
								}
								elsif ( scalar @map_bits == 2 )
								{
									if ( $contribution->{$map_bits[0]}->{$map_bits[1]} )
									{
										$field_value->{$subfield->{sub_name}} = $contribution->{$map_bits[0]}->{$map_bits[1]};
									}
									else
									{
										my @field_bits = split( '_', $map_bits[1] );
										$field_value->{$subfield->{sub_name}} = $entity->get_value( $field_bits[0] );
									}
								}
								elsif ( scalar @map_bits == 3 )
								{
									my @kv = split( '=', $map_bits[2] );
									if ( $contribution->{contributor}->{$kv[0]} eq $kv[1] )
									{
										$field_value->{$subfield->{sub_name}} = $contribution->{contributor}->{$map_bits[1]};
									}
									else
									{
										my @field_bits = split( '_', $map_bits[1] );
										foreach my $efv ( @{ $entity->get_value( $field_bits[0] . 's' ) } )
										{
											if ( $efv->{$kv[0]} eq $kv[1] )
											{
												$field_value->{$subfield->{sub_name}} = $efv->{$field_bits[0]};
												last;
											}
										}
									}
								}
							}
						}
					}
					elsif ( my $map = $entity_contrib_maps->{$field_name} )
					{
						$field_value = $contribution->{contributor}->{$map};
					}
					else
					{
						$field_value = $contribution->{contributor}->{name};
					}
					if ( $field->get_property( 'multiple' ) )
					{
						push @{$changes->{$field_name}}, $field_value;
					}
					else
					{
						$changes->{$field_name} = $field_value;
					}
					last;
				}
			}
		}

		foreach my $field_name ( keys %$changes )
		{
			$eprint->set_value( $field_name, $changes->{$field_name} );
		}
	}
	else
	{
		my @contributions = ();

		foreach my $contrib_fields_id ( keys %$all_contrib_fields )
		{
			my $entity_dataset = $repo->dataset( $contrib_fields_id );
			my $contrib_fields = $all_contrib_fields->{$contrib_fields_id};
			foreach my $contrib_field ( keys %{$all_contrib_fields->{$contrib_fields_id}} )
			{
				next unless $eprint->exists_and_set( $contrib_field );
				my $values = $eprint->value( $contrib_field );
				$values = [ $values ] unless ref( $values );
				my $contrib_type = $contrib_fields->{$contrib_field};
				foreach my $value ( @$values )
				{
					my $contrib_name = ref( $value ) ? $value->{name} : $value;
					$contrib_type = $value->{type} unless $contrib_type;
					my $entity = undef;
					$entity = EPrints::DataObj::Entity::entity_with_id( $entity_dataset, $value->{id}, { type => $primary_id_types->{$contrib_fields_id}, name => $contrib_name } ) if ref( $value ) && $value->{id};
					if ( $entity )
					{
						unless ( $entity->has_name( $contrib_name ) )
						{
							my $names = $entity->get_value( 'names' );
							unshift @$names, { name => $contrib_name };
							$entity->set_value( 'names', $names );
							$entity->commit;
						}
					}
					else
					{
						# Find an entity that matches the entity's name but does not already have an ID.
						$entity = EPrints::DataObj::Entity::entity_with_name( $entity_dataset, $contrib_name, { no_id => 1 } );

						# If an entity is found but the entered field row has an ID, create a new entity including that ID.
						if( $entity && ref( $value ) && $value->{id} )
						{
							my $entity_data = { names => [ { name => $contrib_name } ], ids => [ { id => $value->{id}, id_type => $primary_id_types->{$contrib_fields_id} } ] };
							$entity = $entity_dataset->create_dataobj( $entity_data );
							$entity->commit( 1 );
						}
						elsif ( !$entity )
						{
							my $entity_data = { names => [ { name => $contrib_name } ] };
							$entity_data->{ids} = [ { id => $value->{id}, id_type => $primary_id_types->{$contrib_fields_id} } ] if ref( $value ) && $value->{id} ;
							$entity = $entity_dataset->create_dataobj( $entity_data );
							$entity->commit( 1 );
						}
					}
					push @contributions, { contributor => { entityid => $entity->id, datasetid => $contrib_fields_id }, type => $contrib_type };
				}
			}
		}

		$eprint->set_value( "contributions", \@contributions );
	}

}, id => 'sync_eprint_contributions', priority => 100 );

