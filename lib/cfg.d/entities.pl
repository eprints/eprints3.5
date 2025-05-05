$c->{entities}->{datasets} = [ qw/ person organisation / ];

$c->{entitites}->{primary_id_types}->{person} = 'email';
$c->{entitites}->{primary_id_types}->{organisation} = 'ror';
$c->{entitites}->{primary_id_types}->{default} = $c->{entitites}->{primary_id_types}->{person};

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

    return $name;
};
