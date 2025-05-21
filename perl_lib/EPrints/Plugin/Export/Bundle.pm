package EPrints::Plugin::Export::Bundle;

use EPrints::Plugin::Export;
@ISA = ( "EPrints::Plugin::Export" );

use strict;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Bundle (Base)";
	$self->{accept} = [ 'list/eprint' ];

	$self->{suffix} = ".zip";
	$self->{mimetype} = "application/zip";
	$self->{index} = '';
	$self->{max} = 50;
	$self->{hard_max} = $self->{max};
	# The maximum size of file that will be included in the bundle (in bytes), if used from cmd this is ignored
	$self->{max_filesize} = 100 * 1024 * 1024;

	# use as a base class
	$self->{visible} = "none";
	$self->{advertise} = 0;

	$self->{export_name} = "bundle";
	$self->{extras} = [ ];

	return $self;
}

sub output_eprint
{
	my( $self, $dataobj, %opts ) = @_;

	my $id = $dataobj->get_id();

	# Only apply the max file size if we are online, if you are doing it via cmd you should know what you are doing
	my $max_filesize = ( $self->{session}->is_online ) ? $self->{max_filesize} : 2**63;

	# Generate a part of the index.html file from citations/eprint/bundle_index.xml
	my $index_p = $self->{session}->make_element( "p", class=>"citation" );
	$index_p->appendChild( $dataobj->render_citation_link( "bundle_index", n => [$id, "INTEGER"], url => "$id/$id.html", max_filesize => [$max_filesize, "INTEGER"] ) );
	my $index_string = EPrints::XML::to_string( $index_p, undef, 1 );
	$self->{index} .= $index_string;

	# Generate the $id/$id.html file from citations/eprint/bundle.xml
	my $p = $self->{session}->make_element( "p", class=>"citation" );
	$p->appendChild( $dataobj->render_citation_link( "bundle", n => [$id, "INTEGER"], max_filesize => [$max_filesize, "INTEGER"] ) );
	my $string = EPrints::XML::to_string( $p, undef, 1 );

	$self->{archive}->addDirectory( $id );
	utf8::encode($string); # Filename links can contain unicode characters which need to be encoded
	my $member = $self->{archive}->addString( $self->{header} . "<link rel='stylesheet' href='../style.css' type='text/css'>" . $string, "$id/$id.html" );
	$member->desiredCompressionMethod( COMPRESSION_DEFLATED );

	# Add this eprint's public documents to $id/* and their thumbnails if they exist.
	my @documents = $dataobj->get_all_documents();
	foreach my $doc ( @documents )
	{
		if( $self->{session}->is_online ) {
			if( !$doc->is_public && ( !defined $self->{session}->current_user || !$doc->user_can_view( $self->{session}->current_user ) ) ) {
				next;
			}
		}

		my $fh = $doc->get_stored_file( $doc->get_main )->get_local_copy;
		push @{$self->{file_headers}}, $fh; # If this is a legacy file it can be a temporary copy
		my $src = $fh->filename;

		my $filesize = -s $src;
		next if $filesize > $max_filesize;

		my $dst = "$id/" . $doc->get_main;
		utf8::encode($dst); # Filenames can contain unicode characters (such as right-apostrophe)
		$self->{archive}->addFile( $src, $dst ) or print STDERR "Failed to add document to archive";

		my $pdoc = $doc->search_related( 'issmallThumbnailVersionOf' )->item( 0 );
		next unless defined $pdoc;
		my $pfh = $pdoc->get_stored_file( $pdoc->get_main )->get_local_copy;
		push @{$self->{file_headers}}, $pfh;
		my $psrc = $pfh->filename;
		utf8::encode($psrc);
		# `.jpg` is already compressed so compressing it again would make it larger.
		$self->{archive}->addFile( $psrc, "$dst-small.jpg", COMPRESSION_STORED ) or print STDERR "Failed to add thumbnail to archive";
	}
}

sub output_index
{
	my( $self, $count, $max ) = @_;

	$self->{index} .= "<p>[Export limit of " . $max . " records exceeded.]</p>" if $count >= $max;
	utf8::encode( $self->{index} ); # Filename links can contain unicode characters which need to be encoded

	my $member = $self->{archive}->addString( $self->{header} . "<link rel='stylesheet' href='style.css' type='text/css'>" . $self->{index}, "index.html" );
	$member->desiredCompressionMethod( COMPRESSION_DEFLATED );
}

sub output_list
{
	my( $self, %opts ) = @_;
	my $archive = Archive::Zip->new();
	$self->{archive} = $archive;

	$self->{header} = "<!DOCTYPE html><meta charset=\"utf-8\">";

	# This list of file headers is used to ensure they all last until the end of this function preventing them
	# from being unlinked before `writeToFileNamed`.
	$self->{file_headers} = [];

	# write out some other handy exports
	my $session = $self->{session};
	foreach my $format ( @{ $self->{extras} } )
	{
		my $pl = $session->plugin( "Export::$format" );
		my $fh = File::Temp->new( SUFFIX => $pl->{suffix} );
		push @{$self->{file_headers}}, $fh;
		$pl->initialise_fh( $fh );
		my %popts; $popts{fh} = $fh; $popts{list} = $opts{list};
		$pl->output_list( %popts );
		
		$archive->addFile( $fh->filename, $pl->{name}.$pl->{suffix} );
	}

	# Add the stylesheet from bundle_export.css as style.css
	my $style_path = $session->config( "htdocs_path" ) . "/en/style/bundle_export.css";
	print STDERR "Could not find `bundle_export.css`, have you run `generate_static`?\n" unless -e $style_path;
	$archive->addFile( $style_path, "style.css" );

	my $fallback_path = $session->config( 'htdocs_path' ).'/en/style/images/fileicons/other.png';
	$archive->addFile( $fallback_path, 'fallback.png' );

	# write out the bundle files for each record
	my $count = 1;
	my $max = ( $session->get_online ) ? $self->{max} : $self->{hard_max};
	$opts{list}->map( sub {
		my( $session, $dataset, $dataobj ) = @_;
		if( $count <= $max )
		{
			$self->output_eprint( $dataobj, %opts );
			$count++;
		}
	} );

	$self->output_index($count, $max); # populated by way of output_eprint()

	# zip up the resulting files, send them to the client
	my $zipFile = File::Temp->new( SUFFIX => ".zip" );
	$archive->writeToFileNamed($zipFile->filename) == AZ_OK or print STDERR "Failed to write to temporary zip file";

	binmode( $opts{fh} || \*STDOUT );

	sysseek($zipFile, 0, 0);
	my $buffer;
	while(sysread($zipFile, $buffer, 1048576))
	{
		print {$opts{fh} || \*STDOUT} $buffer;
	}
	close($zipFile);

	return "";
}

1;
