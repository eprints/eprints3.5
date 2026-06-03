# legacy dynamic_template.pl
$c->add_trigger( EP_TRIGGER_DYNAMIC_TEMPLATE, sub {
	my %params = @_;

	my $repo = $params{repository};
	my $pins = $params{pins};

	if( $repo->config( "dynamic_template", "enable" ) )
	{
		if( $repo->can_call( "dynamic_template", "function" ) )
		{
			$repo->call( [ "dynamic_template", "function" ], $repo, $pins );
		}
	}
}, priority => 10000, id => 'call_dynamic_template_function' );

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
