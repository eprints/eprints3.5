push @{$c->{browse_views}},
	id => "person",
	menus => [
		fields => [ "contributions_contributor_id", "contributions_contributor_type" ],
		allow_null => 0,
	],
	order => "-date/title",
	noindex => 1,
	nolink => 1,
	nocount => 0,
	include => 1,
},

