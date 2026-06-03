######################################################################
#
# EPrints::Citation::XSL
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Citation::XSL> - Loading and rendering of XSL based 
citation styles.

=head1 DESCRIPTION

Loads XSL citation style files and renders citations for a particular 
type of data object.

This class inherits from L<EPrints::Citation>.

=head1 METHODS

=cut

package EPrints::Citation::XSL;

use EPrints::Citation;
@ISA = qw( EPrints::Citation );

eval "use XML::LibXSLT 1.70";
use strict;

######################################################################
=pod

=over 4

=item $citation->load_source

Load XSL citation source from file.

Returns 1 if citation source was successfully loaded.

=cut
######################################################################

sub load_source
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $file = $self->{filename};

	my $doc = $repo->parse_xml( $file, 1 );
	return if !$doc;

	my $type = $doc->getDocumentElement->getAttribute( "ept:type" );
	$type = "default" unless EPrints::Utils::is_set( $type );

	my $stylesheet = XML::LibXSLT->new->parse_stylesheet( $doc );

	$self->{type} = $type;
	$self->{stylesheet} = $stylesheet;
	$self->{mtime} = EPrints::Utils::mtime( $file );

	$repo->xml->dispose( $doc );

	return 1;
}

######################################################################
=pod

=item $frag = $citation->render( $dataobj, %opts )

Renders a L<EPrints::DataObj> using this citation style.

Returns a XML document fragment of the citation rendering.

=cut
######################################################################

sub render
{
	my( $self, $dataobj, %opts ) = @_;

	EPrints->abort( "Requires dataobj" )
		if !defined $dataobj;

	$self->freshen;

#	my $xml = $dataobj->to_xml;
#	my $doc = $xml->ownerDocument;
#	$doc->setDocumentElement( $xml );

	my $doc = XML::LibXML::Document->new( '1.0', 'utf-8' );
	$doc->setDocumentElement( $doc->createElement( 'root' ) );

	local $self->{messages} = [];

	my $xslt = EPrints::XSLT->new(
		repository => $self->{repository},
		stylesheet => $self->{stylesheet},
		dataobj => $dataobj,
		dataobjs => {},
		opts => \%opts,
		error_cb => sub { $self->error( @_ ) },
	);

	my $r = $xslt->transform( $doc );

	for( @{$self->{messages}} )
	{
		return $self->{repository}->xml->create_text_node( "$self->{filename}: $_->{type} - $_->{message}" );
	}

	return $self->{repository}->xml->contents_of( $r );
}

######################################################################
=pod

=item $citation->error( $type, $message )

Add C<$message> of C<$type> to array of messages for this citation.

=cut
######################################################################

sub error
{
	my( $self, $type, $message ) = @_;

	push @{$self->{messages}}, {
		type => $type,
		message => $message,
	};
}

1;

######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::Citation>

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
