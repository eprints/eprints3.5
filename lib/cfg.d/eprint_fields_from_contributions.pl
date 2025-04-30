$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
    my( %args ) = @_;
    my( $repo, $eprint, $changed ) = @args{qw( repository dataobj changed )};

	my $ds = $repo->dataset( 'eprint' );
    my $primary_id_types = $repo->config( 'entities', 'primary_id_types' );
	my $all_contrib_fields =  $repo->config( 'entities', 'field_contribution_types', 'eprint' );
	my $all_contrib_maps = $repo->config( 'entities', 'field_contribution_maps', 'eprint' );

    my $datasets = {};
    foreach my $dsid ( @{$repo->config( 'entities', 'datasets' )} )
    {
        $datasets->{$dsid} = $repo->dataset( $dsid );
    }

    my $contributions = $eprint->get_value( "contributions" );
	my $changes = {};
	foreach my $contribution ( @$contributions ) 
	{
		my $entity_contrib_fields = $all_contrib_fields->{$contribution->{contributor}->{datasetid}};
		my $entity_contrib_maps = $all_contrib_maps->{$contribution->{contributor}->{datasetid}};
		my $entity = $datasets->{$contribution->{contributor}->{datasetid}}->dataobj( $contribution->{contributor}->{entityid} );

		foreach my $field_name ( keys %$entity_contrib_fields )
		{
			if ( $entity_contrib_fields->{$field_name} eq $contribution->{type} )
			{
				my $field = $ds->field( $field_name );
				my $field_value;
				if ( my $subfields = $field->get_property( 'fields_cache' ) )
				{
					next unless $entity_contrib_maps->{$field_name};
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
					$changes->{$field_name} = [] unless defined $changes->{$field_name};
					push @{$changes->{$field_name}}, $field_value;
				}
				else
				{
					$changes->{$field_name} =  $field_value;
				}
				last;
			}
		}
	}

	foreach my $field_name ( keys %$changes )
	{
		$eprint->set_value( $field_name, $changes->{$field_name} );
	}

}, id => 'update_from_contributions', priority => 100 );
