#!/usr/bin/perl -w
use strict;

# usage:
# for i in `perl icons.svg.perl`; do perl icons.svg.perl $i | rsvg-convert -o out/$i.png ; done

if (defined $ARGV[0]) {
	while (<DATA>) {
		if (s/^([A-Za-z0-9]*)://) {
			print if $1 eq $ARGV[0];
		} else {
			print;
		}
	}
} else {
	my %types = ();
	while (<DATA>) {
		if (/^([A-Za-z0-9]*):/) { $types{$1} = 1; }
	}
	print join " ", keys %types;
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
