######################################################################
#
# EPrints::Update::Static
#
######################################################################
#
#
######################################################################


=pod

=head1 NAME

B<EPrints::Update::Static

=head1 DESCRIPTION

Update static web pages on demand.

=over 4

=cut

package EPrints::Update::Static;

use File::Find;

use strict;

=item %files = scan_static_dirs( $repo, $static_dirs )

Returns a list of files in $static_dirs where the key is the relative path and
the value is the absolute path.

=cut

sub scan_static_dirs
{
	my( $repo, $static_dirs ) = @_;

	my %files;

	foreach my $dir (@$static_dirs)
	{
		_scan_static_dirs( $repo, $dir, "", \%files );
	}

	return %files;
}

sub _scan_static_dirs
{
	my( $repo, $dir, $path, $files ) = @_;

	File::Find::find({
		wanted => sub {
			return if $dir eq $File::Find::name;
			return if $File::Find::name =~ m#/\.#;
			return if -d $File::Find::name;
			$files->{substr($File::Find::name,length($dir)+1)} = $File::Find::name;
		},
	}, $dir);
}

sub update_static_file
{
	my( $session, $langid, $localpath ) = @_;

	my $repository = $session->get_repository;

	if( $localpath =~ m/\/$/ ) { $localpath .= "index.html"; }

	my $target = $repository->get_conf( "htdocs_path" )."/".$langid.$localpath;

	my @static_dirs = $repository->get_static_dirs( $langid );

	my $source_mtime;
	my $source;
	my $map;

	if( $localpath =~ m# \.html$ #x )
	{
		my $base = $localpath;
		$base =~ s/\.html$//;
		DIRLOOP: foreach my $dir ( @static_dirs )
		{
			foreach my $suffix ( qw/ .html .xpage .xhtml / )
			{
				if( -e $dir.$base.$suffix )
				{
					$source = $dir.$base.$suffix;
					$source_mtime = EPrints::Utils::mtime( $source );
					last DIRLOOP;
				}
			}
		}
	}
	else
	{
		foreach my $dir ( @static_dirs )
		{
			if( -e $dir.$localpath )
			{
				$source = $dir.$localpath; 
				$source_mtime = EPrints::Utils::mtime( $source );
				last;
			}
		}
	}

	if( !defined $source_mtime ) 
	{
		# no source file therefore source file not changed.
		return;
	}

	my $target_mtime = EPrints::Utils::mtime( $target );

	unless ( -e $session->config( "variables_path" ) . "/developer_mode_on" && $session->config( "developer_mode", "disable_static_cache" ) )
	{
		return if( defined $target_mtime && $target_mtime > $source_mtime ); # nothing to do
	}

	$target =~ m/^(.*)\/([^\/]+)/;
	my( $target_dir, $target_file ) = ( $1, $2 );
	
	if( !-e $target_dir )
	{
		EPrints::Platform::mkdir( $target_dir );
	}

	$source =~ m/\.([^.]+)$/;
	my $suffix = $1;

	if( $suffix eq "xhtml" ) 
	{ 
		copy_xhtml( $session, $source, $target, {} ); 
	}
	elsif( $suffix eq "xpage" ) 
	{ 
		copy_xpage( $session, $source, $target, {} ); 
	}
	else 
	{ 
		copy_plain( $source, $target, {} ); 
	}
}

=item update_auto_css( $target_dir, $dirs )

=cut

sub update_auto_css
{
	my( $session, $target_dir, $static_dirs ) = @_;

	my @dirs = map { "$_/style/auto" } grep { defined } @$static_dirs;

	update_auto(
			$session->get_repository,
			"$target_dir/style/auto.css",
			"css",
			\@dirs
		);
}

sub update_auto_js
{
	my( $session, $target_dir, $static_dirs ) = @_;

	my @dirs = map { "$_/javascript/auto" } grep { defined } @$static_dirs;

	update_auto(
			$session->get_repository,
			"$target_dir/javascript/auto.js",
			"js",
			\@dirs,
		);
}

=item $auto = update_auto( $target_filename, $extension, $dirs [, $opts ] )

Update a file called $target_filename by concatenating all of the files found in $dirs with the extension $extension (js, css etc. - may be a regexp).

If more than one file with the same name exists in $dirs then only the last encountered file will be used.

Returns the full path to the resulting auto file.

$opts:

=over 4

=item prefix

Prefix text to the output file.

=item postfix

Postfix text to the output file.

=back

=cut

sub update_auto
{
	my( $repo, $target, $ext, $dirs, $opts ) = @_;

	my $target_dir = $target;
	unless( $target_dir =~ s/\/[^\/]+$// )
	{
		EPrints::abort "Expected filename to write to: $target";
	}

	my $target_time = EPrints::Utils::mtime( $target );
	$target_time = 0 unless defined $target_time;
	my $out_of_date = 0;

	my %map;
	# build a map of every uniquely-named auto file from $dirs
	foreach my $dir (@$dirs)
	{
		opendir(my $dh, $dir) or next;
		# if a file is removed the dir mtime will change
		$out_of_date = 1 if (stat($dir))[9] > $target_time;
		foreach my $fn (readdir($dh))
		{
			next if exists $map{$fn};
			next if $fn =~ /^\./;
			next if $fn !~ /\.$ext$/;
			next if -d "$dir/$fn";

			$out_of_date = 1 if (stat("$dir/$fn"))[9] > $target_time;

			$map{$fn} = "$dir/$fn";
		}
		closedir($dh);

	}

	$out_of_date = 1 if !$out_of_date && -f $repo->config( 'config_path' )."/package.yml" && (stat($repo->config( 'config_path' )."/package.yml"))[9] > $target_time;
	$out_of_date = 1 if !$out_of_date && -f $repo->config( 'base_path' )."/perl_lib/EPrints/SystemSettings.pm" && (stat($repo->config( 'base_path' )."/perl_lib/EPrints/SystemSettings.pm"))[9] > $target_time;

	return $target unless $out_of_date;

	EPrints::Platform::mkdir( $target_dir );

	# to improve speed use raw read/write
	open(my $fh, ">:raw", $target) or EPrints::abort( "Can't write to $target: $!" );

	print $fh Encode::encode_utf8($opts->{prefix}) if defined $opts->{prefix};

	# concat all of the mapped files into a single "auto" file
	foreach my $fn (sort keys %map)
	{
		my $path = $map{$fn};
		print $fh "\n\n\n/* From: $path */\n\n";
		open(my $in, "<:raw", $path) or EPrints::abort( "Can't read from $path: $!" );
		my $buffer = "";
		while(read($in, $buffer, 4096))
		{
			print $fh $buffer;
		}
		close($in);
	}

	print $fh Encode::encode_utf8($opts->{postfix}) if defined $opts->{postfix};

	close($fh);

	return $target;
}

sub copy_file
{
	my( $repo, $from, $to, $wrote_files ) = @_;

	my @path = split '/', $to;
	pop @path;
	EPrints::Platform::mkdir( join '/', @path );

	if( $from =~ /\.xhtml$/ )
	{
		return copy_xhtml( @_ );
	}
	elsif( $from =~ /\.xpage$/ )
	{
		return copy_xpage( $repo, $from, substr($to,0,-6), $wrote_files );
	}
	else
	{
		return copy_plain( @_[1..$#_] );
	}
}

sub copy_plain
{
	my( $from, $to, $wrote_files ) = @_;

	if( !EPrints::Utils::copy( $from, $to ) )
	{
		EPrints::abort( "Can't copy $from to $to: $!" );
	}

	$wrote_files->{$to} = 1;
}


sub copy_xpage
{
	my( $session, $from, $to, $wrote_files ) = @_;

	my $doc = $session->get_repository->parse_xml( $from );

	if( !defined $doc )
	{
		$session->get_repository->log( "Could not load file: $from" );
		return;
	}

	my $html = $doc->documentElement;
	my $parts = {};
	foreach my $node ( $html->getChildNodes )
	{
		my $part = $node->nodeName;
		$part =~ s/^.*://;
		next unless( $part eq "head" || $part eq "body" || $part eq "title" || $part eq "template" );

		$parts->{$part} = $session->make_doc_fragment;
			
		foreach my $kid ( $node->getChildNodes )
		{
			$parts->{$part}->appendChild( 
				EPrints::XML::EPC::process( 
					$kid,
					in => $from,
					session => $session ) ); 
		}
	}
	foreach my $part ( qw/ title body / )
	{
		if( !$parts->{$part} )
		{
			$session->get_repository->log( "Error: no $part element in ".$from );
			EPrints::XML::dispose( $doc );
			return;
		}
	}

	$parts->{page} = delete $parts->{body};
	$to =~ s/.html$//;
	$session->write_static_page( $to, $parts, "static", $wrote_files );

	EPrints::XML::dispose( $doc );
}

sub copy_xhtml
{
	my( $session, $from, $to, $wrote_files ) = @_;

	my $doc = $session->get_repository->parse_xml( $from );

	if( !defined $doc )
	{
		$session->get_repository->log( "Could not load file: $from" );
		return;
	}

	my $html = $doc->documentElement;
	if( !defined $html )
	{
		$session->get_repository->log( "Error: no html element in ".$from );
		EPrints::XML::dispose( $doc );
		return;
	}
	# why clone?
	#$session->set_page( $session->clone_for_me( $elements->{html}, 1 ) );
	$session->set_page( 
		EPrints::XML::EPC::process( 
			$html, 
			in => $from,
			session => $session ) ); 

	$session->page_to_file( $to, $wrote_files );
}





1;



=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=end LICENSE

