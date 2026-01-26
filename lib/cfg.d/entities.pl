$c->{entities}->{datasets} = [ qw/ person organisation / ];

$c->{entities}->{primary_id_types}->{person} = 'email';
$c->{entities}->{primary_id_types}->{organisation} = 'ror';
$c->{entities}->{primary_id_types}->{default} = $c->{entities}->{primary_id_types}->{person};

$c->{entities}->{field_contribution_types}->{eprint}->{person} = {};
$c->{entities}->{field_contribution_types}->{eprint}->{organisation} = {};

$c->{entities}->{person}->{human_serialise_name} = sub
{
    my( $name ) = @_;

    my $human_serialised_name = $name->{family} . ", " . $name->{given};

    return $human_serialised_name;
};

$c->{entities}->{person}->{human_deserialise_name} = sub
{
    my( $serialised_name ) = @_;

	my $name = {};
	my @name_bits = split( ',', $serialised_name );

	$name->{family} = $name_bits[0];
	$name->{family} =~ s/^\s+|\s+$//g if $name->{family};

	$name->{given} = $name_bits[1];
	$name->{given} =~ s/^\s+|\s+$//g if $name->{given};

	$name->{honourific} = '';
	$name->{lineage} = '';

    return $name;
};


$c->{render_entity_names} = sub
{
	my( $session, $field, $names ) = @_;

	my $frag = $session->make_doc_fragment();
	my $ul = $session->make_element( 'ul', class => 'ep_entity_names_list' );

	my $name_field;
	my $from_field;
	my $to_field;
	my $lang_field;

	foreach my $inner_field_config ( @{$field->get_property( 'fields_cache' )}, $field->extra_subfields )
	{
		next unless $inner_field_config->{name};
		my $inner_field = $field->dataset->get_field( $inner_field_config->{name} );
		if ( $inner_field->get_property( 'sub_name' ) eq "name" )
		{
			$name_field = $inner_field;
		}
		elsif ( $inner_field->get_property( 'sub_name' ) eq "from" )
		{
			$from_field = $inner_field;
		}
		elsif ( $inner_field->get_property( 'sub_name' ) eq "to" )
        {
			$to_field = $inner_field;
        }
		elsif ( $inner_field->get_property( 'sub_name' ) eq "lang" )
        {
            $lang_field = $inner_field;
        }
	}

	foreach my $name ( @$names )
	{
		my $li = $session->make_element( 'li' );

		$li->appendChild( $name_field->render_single_value( $session, $name->{name} ) );
		my $daterange = "";
		if ( $name->{from} )
		{
			$daterange = EPrints::Utils::tree_to_utf8( $from_field->render_single_value( $session, $name->{from} ) );
		}
		if ( $name->{to} )
		{
			$daterange .= " " if $name->{from};
			$daterange .= "- " . EPrints::Utils::tree_to_utf8( $to_field->render_single_value( $session, $name->{to} ) );
		}
		elsif ( $name->{from} )
		{
			$daterange .= " -";
		}
		if ( $daterange )
		{
			$li->appendChild( $session->make_text( ' (' . $daterange . ')' ) );
		}
		if ( $name->{lang} )
		{
			$li->appendChild( $session->make_text( ' [' . $session->render_language_name( $name->{lang} ) . ']' ) );
		}
		$ul->appendChild( $li );
	}

	$frag->appendChild( $ul );
	return $frag;
};

$c->{render_entity_ids} = sub
{
    my( $session, $field, $ids ) = @_;

    my $frag = $session->make_doc_fragment();
    my $dl = $session->make_element( 'dl', class => 'ep_entity_ids_list' );

    my $id_field;
    my $id_type_field;
    foreach my $inner_field_config ( @{$field->get_property( 'fields_cache' )} )
    {
		my $inner_field = $field->dataset->get_field( $inner_field_config->{name} );
        if ( $inner_field->get_property( 'sub_name' ) eq "id" )
        {
            $id_field = $inner_field;
			last;
        }
    }

    foreach my $id ( @$ids )
    {
        my $dt = $session->make_element( 'dt' );
		$dt->appendChild( $session->html_phrase( $field->dataset->id . '_id_type_typename_'.$id->{id_type} ) );
		$dl->appendChild( $dt );

		my $dd =  $session->make_element( 'dd' );
		$dd->appendChild( $id_field->render_single_value( $session, $id->{id} ) );
		$dl->appendChild( $dd );

    }

    $frag->appendChild( $dl );
    return $frag;
};
