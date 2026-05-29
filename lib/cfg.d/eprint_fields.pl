
push @{$c->{fields}->{eprint}},

{
	name => 'title',
	type => 'longtext',
	input_rows => 3,
	make_single_value_orderkey => 'EPrints::Extras::english_title_orderkey',
},

{
	name => 'contributions',
	type => 'compound',
	multiple => 1,
	fields => [
		{
			sub_name => 'type',
			type => 'namedset',
			set_name => "contributor_type",
			default_value => 'http://id.loc.gov/vocabulary/relators/aut',
		},
		{
			sub_name => 'contributor',
			type => 'multipart',
			fields => [
				{
					sub_name => 'datasetid',
					type => 'set',
					text_index => 0,
					options => [qw( person organisation )],
					default_value => 'person',
					maxlength => 32,
				},
				{
					sub_name => 'name',
					type => 'text',
				},
				{
					sub_name => 'id_value',
					type => 'text',
				},
				{
					sub_name => 'id_type',
					type => 'set',
					options => [ qw( email username ror url ) ],
					default_value => 'email',
					maxlength => 32,
				},
				{
					sub_name => 'entityid',
					type => 'int',
				},
			],
			render_single_value => 'render_contributions_contributor',
		},
	],
	render_input => 'render_input_contributions',
	fromform => 'contributions_fromform',
	input_boxes => 4,
},

{
	name => 'subjects',
	type => 'subject',
	multiple => 1,
	top => 'subjects',
	browse_link => 'subjects',
},
;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
