=head1 NAME

EPrints::Plugin::Import::Binary

=cut

package EPrints::Plugin::Import::Binary;

use strict;

our @ISA = qw/ EPrints::Plugin::Import /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Binary file (Internal)";
	$self->{visible} = "";
	$self->{advertise} = 0;
	$self->{produce} = [qw()];
	$self->{accept} = [qw()];

	$self->{arguments}->{filename} = undef;
	$self->{arguments}->{mime_type} = undef;

	return $self;
}

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};
	my $dataset = $opts{dataset};
	my $filename = $opts{filename};
	my $mime_type = $opts{mime_type};
	my( $format ) = split /[;,]/, $mime_type;
	
	EPrints->abort( "Requires filename argument" ) if !defined $filename;

	my $rc = 0;

	my $epdata = {
		documents => [{
			main => $filename,
			format => $format,
			files => [{
				filename => $filename,
				mime_type => $format,
				filesize => -s $fh,
				_content => $fh,
			}],
		}],
	};

	if( $dataset->base_id eq "eprint" )
	{
	}
	elsif( $dataset->base_id eq "document" )
	{
		$epdata = $epdata->{documents}->[0];
	}
	elsif( $dataset->base_id eq "file" )
	{
		$epdata = $epdata->{documents}->[0]->{files}->[0];
	}
	
	my @ids;

	my $dataobj = $self->epdata_to_dataobj( $dataset, $epdata );
	push @ids, $dataobj->id if defined $dataobj;

	return EPrints::List->new(
		session => $self->{repository},
		dataset => $dataset,
		ids => \@ids );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
