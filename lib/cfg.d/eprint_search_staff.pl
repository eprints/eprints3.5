# Any changes made here will be lost!
#
# Copy this file to:
# archives/[archiveid]/cfg/cfg.d/
#
# And then make any changes.

$c->{datasets}->{eprint}->{search}->{staff} =
{
	search_fields => [
		{ meta_fields => [qw( eprintid )] },
		{ meta_fields => [qw( userid.username )] },
		{ meta_fields => [qw( userid.name )] },
		{ meta_fields => [qw( dir )] },
		@{$c->{search}{advanced}{search_fields}},
	],
	preamble_phrase => "Plugin/Screen/Staff/EPrintSearch:description",
	title_phrase => "Plugin/Screen/Staff/EPrintSearch:title",
	citation => "result",
	page_size => 20,
	order_methods => {
		"bytitle" 	 => "title"
	},
	default_order => "bytitle",
	show_zero_results => 1,
	staff => 1,
	template => "default_internal",
};

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
