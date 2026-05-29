$c->add_dataset_trigger( 'user', EP_TRIGGER_DEFAULTS, sub {
	my( %params ) = @_;
	my $data = $params{data};

	$data->{hideemail} = 'TRUE';

	# Default columns show in Items screens
	$data->{items_fields} = [ 'lastmod', 'title', 'type', 'eprint_status' ];
}, id => 'core_user_defaults' );

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
