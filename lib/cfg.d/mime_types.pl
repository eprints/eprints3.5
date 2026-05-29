# Load mimemap from /etc/mime.types

foreach my $mime_types (
	$c->{base_path} . "/lib/mime.types",
	"/etc/mime.types",
	)
{
	if( open(my $fh, "<", $mime_types) )
	{
		while(defined(my $line = <$fh>))
		{
			next if $line =~ /^\s*#/;
			next if $line !~ /\S/;
			chomp($line);
			my( $mt, @ext ) = split /\s+/, $line;
			$c->{mimemap}->{$_} = $mt for @ext;
		}
		close($fh);
	}
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
