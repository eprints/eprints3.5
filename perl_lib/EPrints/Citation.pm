######################################################################
#
# EPrints::Citation
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Citation> - Loading and rendering of citation styles.

=head1 DESCRIPTION

Renders citations for data objects using a particular style defined
in it own configuration file.

This is an abstract class used by L<EPrints::Citation::EPC> and 
L<EPrints::Citation::XSL> whichb use XML EPC and XSL respectively to
define citation style files.

=head2 SYNOPSIS

	my $citation = $repo->dataset( "eprint" )->citation( "default" );

	$ok = $citation->freshen();

	$citation->render( $eprint, %opts );

=head1 METHODS

=cut 

package EPrints::Citation;

use strict;

######################################################################
=pod

=over 4

=item $citation = EPrints::Citation->new( $filename, %opts )

Returns a new EPrints::Citation object read from C<$filename>.

Options:
    dataset - dataset this citation belongs to

=cut
######################################################################

sub new
{
	my( $class, $filename, %self ) = @_;

	$self{filename} = $filename;
	$self{repository} ||= $self{dataset}->repository;

	my $self = bless \%self, $class;

	Scalar::Util::weaken($self{repository})
		if defined &Scalar::Util::weaken;

	return undef if !$self->freshen();

	return $self;
}

######################################################################
=pod

=item $ok = $citation->freshen()

Attempts to reload the citation source file.

Returns C<undef> if the file could not be loaded.

=cut
######################################################################

sub freshen
{
	my( $self ) = @_;

	my $file = $self->{filename};
	my $mtime = EPrints::Utils::mtime( $file );
	my $old_mtime = $self->{mtime};

	if( defined $old_mtime && $old_mtime == $mtime )
	{
		return;
	}

	return $self->load_source();
}

######################################################################
=pod

=item $ok = $citation->load_source()

Reads the source file.

=cut
######################################################################

sub load_source
{
	return undef;
}

######################################################################
=pod

=item $frag = $citation->render( $dataobj, %opts )

Renders a L<EPrints::DataObj> using this citation style.

=cut
######################################################################

sub render
{
	my( $self, $dataobj, %opts ) = @_;
}

######################################################################
=pod

=item $type = $citation->type()

Returns the type of this citation. Only supported value is 
C<table_row>.

=cut
######################################################################


sub type
{
	shift->{type};
}

1;

=back

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
