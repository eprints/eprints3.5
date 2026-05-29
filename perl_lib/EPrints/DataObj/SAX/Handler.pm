######################################################################
#
# EPrints::DataObj::SAX::Handler
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::SAX::Handler> - SAX handler for EPrints data 
objects.

=head1 DESCRIPTION

This class provides a SAX handler for parsing EPrints data objects.

=head1 METHODS

=cut

package EPrints::DataObj::SAX::Handler;


######################################################################
=pod

=head2 Constructor Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item EPrints::DataObj::SAX::Handler->new

Create new SAX Handler.

=cut
######################################################################

sub new
{
    my( $class, @self ) = @_;

    return bless \@self, $class;
}

sub AUTOLOAD {}


######################################################################
=pod

=back

=head2 Object Methods

=back
######################################################################

######################################################################
=pod

=over 4

=item $sax_handler->start_element( $data )

Use C<$data> to start a new element.

=cut
######################################################################

sub start_element
{
    my( $self, $data ) = @_;
    $self->[0]->start_element( $data, @$self[1..$#$self] );
}

######################################################################
=pod

=item $sax_handler->end_element( $data )

Use C<$data> to end an element.

=cut
######################################################################

sub end_element
{
    my( $self, $data ) = @_;
    $self->[0]->end_element( $data, @$self[1..$#$self] );
}


######################################################################
=pod

=item $sax_handler->characters( $data )

Use C<$data> to add characters to element.

=cut
######################################################################

sub characters
{
    my( $self, $data ) = @_;
    $self->[0]->characters( $data, @$self[1..$#$self] );
}

1;

######################################################################
=pod

=back

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
