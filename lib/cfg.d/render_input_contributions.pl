
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

	my $dsids = $c->{entities}->{datasets};
	my $datasets = {};
	foreach my $dsid ( @{$c->{entities}->{datasets}} )
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
		my $ef_basename = $basename . "_" . $y . "_contributor_entity";
		my $enf_name = $ef_basename . "_name";
		my $enf_value = undef;
		my $eivf_name = $ef_basename . "_id_value";
		my $eivf_value = undef;
		my $eitf_name = $ef_basename . "_id_type";
	 	my $eitf_value = undef;
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
            class => "ep_form_text ep_eprint_${ef_baseclass}_name eptype_eprint_text",
            name => $enf_name,
            id => $enf_name,
            value => $enf_value,
            size => 30,
            maxlength => 60,
            'aria-labelledby' => $self->get_labelledby( $enf_name ),
            'aria-describedby' => $self->get_describedby( $enf_name, $one_field_component ),
        );
        $entity_field->appendChild( $enf_input );
        my $eivf_input = $session->render_noenter_input_field(
            class => "ep_form_text ep_eprint_${ef_baseclass}_id_value eptype_eprint_text",
            name => $eivf_name,
            id => $eivf_name,
            value => $eivf_value,
            size => 30,
            maxlength => 60,
            'aria-labelledby' => $self->get_labelledby( $eivf_name ),
            'aria-describedby' => $self->get_describedby( $eivf_name, $one_field_component ),
        );
        $entity_field->appendChild( $eivf_input );
        my $eitf_input = $session->render_option_list(
            class => "ep_form_text ep_eprint_${ef_baseclass}_id_type eptype_eprint_select",
            name => $eitf_name,
            id => $eitf_name,
            default => $eitf_value,
			values => \@eitf_options,
			labels => $eitf_labels,
            'aria-labelledby' => $self->get_labelledby( $eitf_name ),
            'aria-describedby' => $self->get_describedby( $eitf_name, $one_field_component ),
        );
        $entity_field->appendChild( $eitf_input );

        my $eif_name = $ef_basename . "id";
        my $entityid_input = $session->xhtml->input_field( id => $eif_name, type => 'hidden', name => $eif_name, value => $contributor_entityid );
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
        push @params, dataset => $self->{dataset}->id;
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
}
