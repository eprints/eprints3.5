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

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

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

=for LICENSE END

