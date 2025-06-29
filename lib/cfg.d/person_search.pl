
$c->{search}->{person} = 
{
	search_fields => [
		{ meta_fields => [ "name", ] },
		{ meta_fields => [ "names_name", ] },
		{ meta_fields => [ "id_value", ] },
		{ meta_fields => [ "ids_id", ] },
		{ meta_fields => [ "dept" ] },
		{ meta_fields => [ "organisation" ] },	
		{ meta_fields => [ "address", "country" ] },
	],
	citation => "result",
	page_size => 20,
	order_methods => {
		"byname" 	 =>  "name/lastmod",
		"bylastmod"	 =>  "lastmod/name",
		"byrevlastmod" =>  "-lastmod/name",
	},
	default_order => "byname",
	show_zero_results => 1,
};


=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2025 University of Southampton.
EPrints 3.5 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.5/

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints 3.5 L<http://www.eprints.org/>.

EPrints 3.5 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.5 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.5.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

