$c->add_dataset_trigger( 'document', EP_TRIGGER_DEFAULTS, sub {
	my( %params ) = @_;
	my $repo = $params{repository};
	my $data = $params{data};

	$data->{language} = $repo->get_langid();
	$data->{security} = 'public';
}, id => 'core_document_defaults' );

$c->{eprint_details_document_fields} = [
        "content",
        "format",
        "formatdesc",
        "language",
        "security",
        "license",
        "date_embargo",
        "embargo_reason",
];

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

