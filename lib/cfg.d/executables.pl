# set this to 1 if disk free doesn't work on your system
$c->{disable_df} = 0 if !defined $EPrints::SystemSettings::conf->{disable_df};
$c->{executables} ||= {};

# location of executables
{
use Config; # for perlpath
my %executables = (
	  'convert' => '/usr/bin/convert',
	  'tar' => '/bin/tar',
	  'rm' => '/bin/rm',
	  'dvips' => '/usr/bin/dvips',
	  'gunzip' => '/bin/gunzip',
	  'sendmail' => '/usr/sbin/sendmail',
	  'unzip' => '/usr/bin/unzip',
	  'html2text' => '/usr/bin/html2text',
	  'cp' => '/bin/cp',
	  'latex' => '/usr/bin/latex',
	  'perl' => $Config{perlpath},
	  'pdftotext' => '/usr/bin/pdftotext',
	  'wget' => '/usr/bin/wget',
	  'antiword' => '/usr/bin/antiword',
	  'ffmpeg' => '/usr/bin/ffmpeg',
	  'file' => '/usr/bin/file',
	  'doc2txt' => "$c->{base_path}/tools/doc2txt",
	  'rtf2txt' => "$c->{base_path}/tools/rtf2txt",
	  'unoconv' => '/usr/bin/unoconv',
	  'txt2refs' => "$c->{base_path}/tools/txt2refs",
	  'ffprobe' => '/usr/bin/ffprobe',
	  'cal' => '/usr/bin/cal',
	  'ncal' => '/usr/bin/ncal',
	);
my @paths = EPrints->system->bin_paths;
EXECUTABLE: while(my( $name, $path ) = each %executables)
{
	next if exists $c->{executables}->{$name};
	if( -x $path )
	{
		$c->{executables}->{$name} = $path;
		next EXECUTABLE;
	}
	for(@paths)
	{
		if( -x "$_/$name" )
		{
			$c->{executables}->{$name} = "$_/$name";
			next EXECUTABLE;
		}
	}
}
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
