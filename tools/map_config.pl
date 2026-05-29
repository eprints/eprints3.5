#!/usr/bin/perl -w

use FindBin;

my $dh;
my @files = ();
my $flavour = @ARGV ? $ARGV[0] : "zero";
my $path = $flavour eq "zero" ? "$FindBin::Bin/../lib/defaultcfg_zero/cfg.d" : "$FindBin::Bin/../flavours/".$flavour."_lib/defaultcfg/cfg.d";
opendir( $dh, $path ) || die "$path couldn't be opened ...";
while( my $file = readdir( $dh ) )
{
	push @files, $file;
}
closedir( $dh );

my $byfile = {};
my $byopt = {};

foreach my $file ( @files )
{
	my $fn = "$path/$file";
	open( F, $fn ) || die "dang $fn : $!";
	foreach my $line ( <F> )
	{
		chomp $line;
		if( $line =~ m/^\s*\$c->\{([^}]+)\}/ )
		{
			$byfile->{$file}->{$1} = 1;
			$byopt->{$1}->{$file} = 1;
		} 
	}	
	close F;
}

foreach my $file ( sort keys %$byfile )
{
	print "== $file ==\n";
	foreach my $opt ( sort keys %{$byfile->{$file}} )
	{
		print "* $opt\n";
	}
}
print "\n\n\n";

foreach my $opt ( sort keys %$byopt )
{
	print "* $opt = [[".join( "]], [[", sort keys %{$byopt->{$opt}})."]]\n";
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
