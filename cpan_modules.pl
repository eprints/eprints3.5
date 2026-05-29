#!/usr/bin/env perl

BEGIN { # Add the path to INC so that it can find 'Bundle::EPrints'
	my $path = $0;
	$path =~ s/cpan_modules\.pl$/./g;
	$path .= '/perl_lib/EPrints';
	push @INC, $path;
}

use CPAN;

#
# Set the umask so nothing goes odd on systems which
# change it.
#
umask( 0022 );

print "Attempting to install PERL modules required by GNU EPrints...\n";

# Lives in <eprint_path>/perl_lib/EPrints/Bundle/EPrints.pm
install( 'Bundle::EPrints' );

CPAN::Shell->notest( 'install', 'XML::LibXSLT' ); # Test will complain even though install is successful

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
