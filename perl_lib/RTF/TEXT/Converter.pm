package RTF::TEXT::Converter;
$RTF::TEXT::Converter::VERSION = '1.12';
use strict;
use warnings;

use RTF::Control;
use RTF::TEXT::Converter::ansi;
use RTF::TEXT::Converter::charmap;

@RTF::TEXT::Converter::ISA = qw(RTF::Control);

use constant TRACE                => 0;
use constant LIST_TRACE           => 0;
use constant SHOW_RTF_LINE_NUMBER => 0;

=head1 NAME

RTF::TEXT::Converter - Perl extension for converting RTF into text

=head1 VERSION

version 1.12

=head1 DESCRIPTION

Perl extension for converting RTF into text

=head1 SYNOPSIS

	use strict;
	use RTF::TEXT::Converter;

	my $object = RTF::TEXT::Converter->new(

		output => \*STDOUT

	);

	$object->parse_stream( \*RTF_FILE );

OR

	use strict;
	use RTF::TEXT::Converter;

	my $object = RTF::TEXT::Converter->new(

		output => \$string

	);

	$object->parse_string( $rtf_data );

=head1 METHODS

=head2 new()

Constructor method. Currently takes one named parameter, C<output>,
which can either be a reference to a filehandle, or a reference to
a string. This is where our text output will end up.

=head2 parse_stream()

Read RTF in from a filehandle, and start processing it. Pass me
a reference to a filehandle.

=head2 parse_string()

Read RTF in from a string, and start processing it. Pass me a string.

=head1 JUST SO YOU KNOW

You can mix-and-match your output and input methods - nothing to stop
you outputting to a string when you've read from a filehandle...

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>, originally by Philippe Verdret

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
