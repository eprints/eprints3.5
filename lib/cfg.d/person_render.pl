$c->{person_page_metadata} = [qw/
	name
	names
	ids
	dept
	organisation
	address
	country
	url
/];

######################################################################
=pod

=over

=item $xhtmlfragment = person_render( $person, $repository, $preview )

This subroutine takes a person object and renders the XHTML view
of this person for public viewing.

Takes two arguments: the L<$person|EPrints::DataObj::Person> to render
and the current L<$repository|EPrints::Session>.

Returns a list of ( C<$page>, C<$title>[, C<$links>[, C<$template>]] )
where C<$page>, C<$title> and C<$links> are XHTML DOM objects and
C<$template> is a string containing the name of the template to use
for this page.

If $preview is true then this is only being shown as a preview. The 
C<$template> isn't honoured in this situation. (This is used to stop 
the "edit person" link appearing when it makes no sense.)

=back

=cut

######################################################################

$c->{person_render} = sub
{
	my( $person, $repository, $preview ) = @_;

	my $flags = { 
		preview => $preview,
	};
	my %fragments = ();

	foreach my $key ( keys %fragments ) { $fragments{$key} = [ $fragments{$key}, "XHTML" ]; }
	
	my $page = $person->render_citation( "entity_page", %fragments, flags=>$flags );

	my $title = $person->render_citation( "brief" );

	my $links = $repository->xml()->create_document_fragment();

	return( $page, $title, $links );
};

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
