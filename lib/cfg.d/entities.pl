$c->{entities}->{datasets} = [ qw/ person organisation / ];

$c->{entities}->{person}->{human_serialise_name} = sub
{
    my( $class, $name ) = @_;

    my $human_serialised_name = $name->{family} . ", " . $name->{given};

    return $human_serialised_name;
};

$c->{entities}->{person}->{human_deserialise_name} = sub
{
    my( $class, $serialised_name ) = @_;

	my $name = {};
	my @name_bits = split( ',', $serialised_name );

	$name->{family} = $name_bits[0];
	$name->{family} =~ s/^\s+|\s+$//g;

    $name->{given} = $name_bits[1];
    $name->{given} =~ s/^\s+|\s+$//g;

    return $name;
};
