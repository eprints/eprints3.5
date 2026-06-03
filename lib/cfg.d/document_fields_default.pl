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

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
