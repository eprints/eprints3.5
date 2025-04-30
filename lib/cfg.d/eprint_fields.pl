
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
            default_value => 'http://www.loc.gov/loc.terms/relators/AUT',
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

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2024 University of Southampton.
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

