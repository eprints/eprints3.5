# EPrints Services package
# split field value into paragraphs
$c->{render_paras} = sub {
	my( $session, $field, $value, $object ) = @_;

	return undef if (caller(0))[0] eq "EPrints::Extras";

	my $frag = $session->make_doc_fragment;

	# normalise newlines
	$value =~ s/(\r\n|\n|\r)/\n/gs;

	my @paras = split( /\n\n/, $value );
	foreach my $para( @paras )
	{
		$para =~ s/^\s*\n?//;
		$para =~ s/\n?\s*$//;
		next if $para eq "";

		#my $p = $session->make_element( "p", style=>"text-align: left; margin: 1em auto 0em auto" );
		#	ADB: Commented out the above and added below. 1em top margin results in field not aligning vertically with field name.
    #	Better to replace inline style with a class. Default seems OK in any case.
		my $p = $session->make_element( "p", class=>"ep_field_para" ); 

		my @lines = split( /\n/, $para );
		for( my $i=0; $i<scalar( @lines ); $i++ )
		{
			$p->appendChild( $session->make_text( $lines[$i] ) );
			$p->appendChild( $session->make_element( "br" ) ) unless $i == $#lines;
		}

		$frag->appendChild( $p );
	}

	return $frag;
};

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
