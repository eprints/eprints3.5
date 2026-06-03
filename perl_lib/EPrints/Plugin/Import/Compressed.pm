=head1 NAME

EPrints::Plugin::Import::Compressed

=cut

package EPrints::Plugin::Import::Compressed;

use strict;

use EPrints::Plugin::Import::Binary;
use EPrints::Plugin::Import::Archive;
use URI;

our @ISA = qw/ EPrints::Plugin::Import::Archive /;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Unpack an archive (.zip or .tar.gz)";
	$self->{visible} = "all";
	$self->{advertise} = 0;
	$self->{produce} = [qw( dataobj/document dataobj/eprint )];
	$self->{accept} = [qw( application/zip application/x-zip application/x-gzip sword:http://purl.org/net/sword/package/SimpleZip )];
	$self->{actions} = [qw( unpack )];

	return $self;
}

sub input_fh
{
	my( $self, %opts ) = @_;

	my $fh = $opts{fh};
	my $dataset = $opts{dataset};
	
	my %flags = map { $_ => 1 } @{$opts{actions} || []};

	# default behaviour is just to create a one-file object (either eprint or
	# document)
	return $self->EPrints::Plugin::Import::Binary::input_fh( %opts )
		if !$flags{unpack};

	my $rc = 0;

	my( $type, $zipfile ) = $self->upload_archive($fh);

	my $repo = $self->{session};

	my $dir = $self->add_archive($zipfile, $type );

	my $epdata;

	if( $dataset->base_id eq "document" )
	{
		$epdata = $self->create_epdata_from_directory( $dir, 1 );
		$self->handler->message("error", $@), return if !defined $epdata;
	}
	elsif( $dataset->base_id eq "eprint" )
	{
		$epdata = $self->create_epdata_from_directory( $dir, 0 );
		$self->handler->message("error", $@), return if !defined $epdata;
		$epdata = {
			documents => $epdata,
		};
	}
	
	my @ids;

	my $dataobj = $self->epdata_to_dataobj( $dataset, $epdata );
	push @ids, $dataobj->id if defined $dataobj;

	return EPrints::List->new(
		session => $repo,
		dataset => $dataset,
		ids => \@ids );
}


######################################################################
=pod

=item $success = $doc->upload_archive( $filehandle, $filename, $archive_format )

Upload the contents of the given archive file. How to deal with the 
archive format is configured in SystemSettings. 

(In case the over-loading of the word "archive" is getting confusing, 
in this context we mean ".zip" or ".tar.gz" archive.)

=cut
######################################################################

sub upload_archive
{
	my( $self, $fh ) = @_;

	use bytes;

	binmode($fh);

	my $zipfile = File::Temp->new();
	binmode($zipfile);

	my $rc;
	my $lead;
	while($rc = sysread($fh, my $buffer, 4096))
	{
		$lead = $buffer if !defined $lead;
		syswrite($zipfile, $buffer);
	}
	EPrints->abort( "Error reading from file handle: $!" ) if !defined $rc;

	my $type = substr($lead,0,2) eq "PK" ? "zip" : "targz";

	return($type, $zipfile);
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
