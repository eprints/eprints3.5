$c->add_dataset_trigger( 'eprint', EP_TRIGGER_DEFAULTS, sub {
	my( %params ) = @_;

	$params{data}->{type} = 'other';
}, id => 'default_eprint_type_other' );

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
