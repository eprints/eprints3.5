push @{$c->{fields}->{person}},
{
    name => 'dept',
    type => 'text',
},

{
    name => 'organisation',
    type => 'itemref',
 	datasetid => 'organisation',
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
