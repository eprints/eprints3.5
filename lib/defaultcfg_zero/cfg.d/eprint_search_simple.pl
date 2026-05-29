$c->{search}->{simple} = 
{
	search_fields => [
		{
			id => "q",
			meta_fields => [
				"documents",
				"title",
			]
		},
	],
#	preamble_phrase => "cgi/search:preamble",
	title_phrase => "cgi/search:simple_search",
	citation => "result",
	page_size => 20,
	order_methods => {
		"bytitle" 	 => "title/type"
	},
	default_order => "bytitle",
	show_zero_results => 1,
	template => "default",
};
		

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
