=head1 NAME

EPrints::Page::DOM

=cut

######################################################################
#
# EPrints::Page::DOM
#
######################################################################
#
#
######################################################################

package EPrints::Page::DOM;

@ISA = qw/ EPrints::Page /;

use strict;

sub new
{
	my( $class, $repository, $page_dom, %options ) = @_;

	EPrints::Utils::process_parameters( \%options, {
		   add_doctype => 1,
	});

	return bless { repository=>$repository, page_dom=>$page_dom, %options }, $class;
}

sub send
{
	my( $self, %options ) = @_;

	if( !defined $self->{page_dom} ) 
	{
		EPrints::abort( "Attempt to send the same page object twice!" );
	}

	$self->{page} =
		$self->{repository}->xhtml->to_xhtml( $self->{page_dom} );

	$self->SUPER::send( %options );

	EPrints::XML::dispose( $self->{page_dom} );
	delete $self->{page_dom};
}

sub write_to_file
{
	my( $self, $filename, $wrote_files ) = @_;
	
	if( !defined $self->{page_dom} ) 
	{
		EPrints::abort( "Attempt to write the same page object twice!" );
	}

	$self->{page} =
		$self->{repository}->xhtml->to_xhtml( $self->{page_dom} );

	$self->SUPER::write_to_file( $filename );

	if( defined $wrote_files )
	{
		$wrote_files->{$filename} = 1;
	}

	EPrints::XML::dispose( $self->{page_dom} );
	delete $self->{page_dom};
}

sub DESTROY
{
	my( $self ) = @_;

	if( defined $self->{page_dom} )
	{
		EPrints::XML::dispose( $self->{page_dom} );
	}
}

1;


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
