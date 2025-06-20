=head1 NAME

EPrints::Plugin::Import::PDF

=cut

package EPrints::Plugin::Import::PDF;

@ISA = qw( EPrints::Plugin::Import );

use Image::ExifTool qw(:Public);
use strict;
use utf8;

sub new
{
	my( $class, %opts ) = @_;
	my $self = $class->SUPER::new( %opts );
	my $repo = $self->{repository};

	$self->{name} = "PDF";
	$self->{visible} = "all";
	$self->{accept} = [ 'application/pdf' ];
	$self->{produce} = [ 'dataobj/eprint', 'list/eprint' ];
	$self->{actions} = [ 'metadata' ] if $repo->config( 'pdf_metadata_enabled' );

	return $self;
}

sub input_fh
{
	my( $plugin, %opts ) = @_;

	my $epdata = $plugin->generate_epdata( %opts );

	my @ids;
	my $dataobj = $plugin->epdata_to_dataobj( $opts{dataset}, $epdata );
	push @ids, $dataobj->id if $dataobj;

	return EPrints::List->new(
		dataset => $opts{dataset},
		session => $plugin->{session},
		ids => \@ids,
	);
}

sub generate_epdata
{
	my( $plugin, %opts ) = @_;

	my $repository = $plugin->{repository};
	my $filename = $opts{filename};

	my %flags = map { $_ => 1 } @{$opts{actions}};

	my $filepath = "$opts{fh}";
	if( !-f $filepath ) {
		$filepath = File::Temp->new;
		binmode( $filepath );
		while( sysread( $opts{fh}, $_, 4096 ) ) {
			syswrite( $filepath, $_ );
		}
		seek( $opts{fh}, 0, 0 );
		seek( $filepath, 0, 0 );
	}

	my $epdata = {
		documents => [{
			format => "application/pdf",
			main => $filename,
			files => [{
				filename => $filename,
				filesize => (-s $opts{fh}),
				_content => $opts{fh},
			}],
		}],
	};

	# Early return if we don't want to add metadata
	if( !$flags{metadata} ) {
		return $epdata;
	}

	$plugin->{exifTool} = Image::ExifTool->new;
	# By ignoring minor errors we can do questionable actions like extracting over 1000 creators from a file.
	$plugin->{exifTool}->ExtractInfo( $filepath, { IgnoreMinorErrors => 1 } ) or print STDERR "Failed to extract information from file: ", $!, ", ";

	$epdata->{title} = $plugin->get_info( "title_metadata" );
	if( !defined $epdata->{title} && $opts{multiple} ) {
		# If we are importing multiple files and didn't set title then we should set it to the $filename to make it clearer in the list
		$epdata->{title} = $filename;
	}

	# Create a dummy workflow so that we can test whether it contains the 'contributions' field
	my $fake_eprint = bless { dataset => $repository->dataset( 'eprint' ) }, 'EPrints::DataObj';
	my $workflow = EPrints::Workflow->new( $repository, 'default', item => $fake_eprint );
	my $has_contributions = $workflow->{field_stages}->{contributions} && 1;

	# If it does contain contributions then we want to add the information to 'contributions' rather than 'creators'
	my @author_texts = $plugin->get_info( "authors_metadata" );
	for my $author_text (@author_texts) {
		my @authors = $plugin->parse_author( $author_text, $has_contributions );
		if( $has_contributions ) {
			push @{$epdata->{contributions}}, @authors;
		} else {
			push @{$epdata->{creators}}, @authors;
		}
	}

	my $publisher = $plugin->get_info( 'publisher_metadata' );
	if( $publisher ) {
		if( $has_contributions ) {
			push @{$epdata->{contributions}}, {
				type => $plugin->{repository}->config('entities', 'field_contribution_types', 'eprint', 'organisation', 'publisher'),
				contributor => {
					datasetid => 'organisation',
					name => $publisher,
				}
			};
		} else {
			$epdata->{publisher} = $publisher;
		}
	}

	$epdata->{publication} = $plugin->get_info( "publication_metadata" );
	$epdata->{issn} = $plugin->get_info( "issn_metadata" );
	$epdata->{official_url} = $plugin->get_info( "official_url_metadata" );
	$epdata->{volume} = $plugin->get_info( "volume_metadata" );
	$epdata->{number} = $plugin->get_info( "number_metadata" );

	$epdata->{pages} = $plugin->get_info( "page_count_metadata" );
	if( my $pageRange = $plugin->get_info( "page_range_metadata" ) ) {
		if( $pageRange =~ /-/ ) {
			$epdata->{pagerange} = $pageRange;
		} else {
			$epdata->{article_number} = $pageRange;
		}
	} else {
		my $pageStart = $plugin->get_info( "page_start_metadata" );
		my $pageEnd = $plugin->get_info( "page_end_metadata" );
		if( defined $pageStart && defined $pageEnd ) {
			$epdata->{pagerange} = "$pageStart-$pageEnd";
		}
		# TODO: I think some people may put `article_number` in $pageStart with nothing in $pageEnd so that is something we could catch
	}

	if( $epdata->{date} = $plugin->parse_date( $plugin->get_info( "date_metadata" ) ) ) {
		$epdata->{date_type} = $repository->config( "date_type_metadata_default" );
		# If we added the date it was published then it must be published.
		if( $epdata->{date_type} == "published" ) {
			$epdata->{ispublished} = "pub";
		}
	}

	$epdata->{id_number} = $plugin->get_info( "id_number_metadata" );
	if( $epdata->{id_number} && $repository->config( "fill_url_with_id_number" ) ) {
		$epdata->{official_url} ||= "https://doi.org/".$epdata->{id_number};
	}

	return $epdata;
}

sub get_info
{
	my( $plugin, $metadata ) = @_;

	my @fields = @{ $plugin->{repository}->config($metadata) };

	foreach my $field (@fields) {
		my $info = $plugin->{exifTool}->GetInfo( $field );
		my @items = map {
			my $item = $info->{$_};
			utf8::decode($item);
			$item
		} sort keys %$info;

		if( $items[0] ) {
			return wantarray ? @items : $items[0];
		}
	}

	return;
}

sub parse_author
{
	my( $plugin, $authors, $has_contributions ) = @_;
	my $repo = $plugin->{repository};

	my @parsed;
	foreach my $author (split(/,|&| and |\t|;/, $authors)) {
		my $name = $repo->config( 'format_imported_author' )->( $author, $has_contributions );

		if( $has_contributions ) {
			push @parsed, {
				type => $plugin->{repository}->config('entities', 'field_contribution_types', 'eprint', 'person', 'creators'),
				contributor => {
					datasetid => 'person',
					name => $name,
				}
			}
		} else {
			push @parsed, { name => $name };
		}
	}

	return @parsed;
}

sub parse_date
{
	my( $plugin, $date ) = @_;

	# XMP date is formatted as '%Y:%m:%d %H:%M:%S%z' (although %z is hh:mm rather than hhmm (and occasionally Z rather than +00:00))
	# And we are converting to eprints date which is '%Y-%m-%d'

	if( defined $date ) {
		($date) = split(' ', $date, 2);
		$date =~ s/:/-/g;
	}

	return $date;
}
