
$c->{search}->{user} = 
{
	search_fields => [
		{ meta_fields => [ "name", ] },
		{ meta_fields => [ "username", ] },
		{ meta_fields => [ "userid", ] },
		{ meta_fields => [ "usertype", ] },
		{ meta_fields => [ "email" ] },
	],
	citation => "result",
	page_size => 20,
	order_methods => {
		"byname" 	 =>  "name/joined",
		"byjoin"	 =>  "joined/name",
		"byrevjoin"  	 =>  "-joined/name",
		"bytype" 	 =>  "usertype/name",
	},
	default_order => "byname",
	show_zero_results => 1,
};


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
