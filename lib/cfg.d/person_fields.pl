push @{$c->{fields}->{person}},
{
	name => 'dept',
	type => 'text',
},

{
	name => 'organisation',
	type => 'dataobjref',
	datasetid => 'organisation',
	fields => [
		{
			sub_name => 'name',
			type => 'text',
			input_cols => 35,
		},
		{
			sub_name => 'id_value',
			type => 'id',
			input_cols =>  30,
		},
	],
},

{
	name => 'address',
	type => 'longtext',
	input_rows => 5,
},

{
	name => 'country',
	type => 'text',
},

{
	name => 'url',
	type => 'url',
},
;
