$c->{organisation_page_metadata} = [qw/
	name
	names
	ids
	address
	country
/];

######################################################################
=pod

=over

=item $xhtmlfragment = organisation_render( $organisation, $repository, $preview )

This subroutine takes an organisation object and renders the XHTML view
of this organisation for public viewing.

Takes two arguments: the L<$organisation|EPrints::DataObj::Organisation> to render
and the current L<$repository|EPrints::Session>.

Returns a list of ( C<$page>, C<$title>[, C<$links>[, C<$template>]] )
where C<$page>, C<$title> and C<$links> are XHTML DOM objects and
C<$template> is a string containing the name of the template to use
for this page.

If $preview is true then this is only being shown as a preview. The 
C<$template> isn't honoured in this situation. (This is used to stop 
the "edit organisation" link appearing when it makes no sense.)

=back

=cut

######################################################################

$c->{organisation_render} = sub
{
	my( $organisation, $repository, $preview ) = @_;

	my $flags = { 
		preview => $preview,
	};
	my %fragments = ();

	foreach my $key ( keys %fragments ) { $fragments{$key} = [ $fragments{$key}, "XHTML" ]; }
	
	my $page = $organisation->render_citation( "entity_page", %fragments, flags=>$flags );

	my $title = $organisation->render_citation( "brief" );

	my $links = $repository->xml()->create_document_fragment();

	return( $page, $title, $links );
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

