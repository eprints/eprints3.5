=head1 NAME

EPrints::Plugin::Export::TextFile

=cut

package EPrints::Plugin::Export::TextFile;

# This virtual super-class supports Unicode output

our @ISA = qw( EPrints::Plugin::Export );

sub new
{
	my( $class, %params ) = @_;

	$params{mimetype} = exists $params{mimetype} ? $params{mimetype} : "text/plain; charset=utf-8";
	$params{suffix} = exists $params{suffix} ? $params{suffix} : ".txt";

	return $class->SUPER::new( %params );
}

sub initialise_fh
{
	my( $plugin, $fh ) = @_;

	binmode($fh, ":utf8");
}

# Windows Notepad and other text editors will use a BOM to determine the
# character encoding
sub byte_order_mark
{
	return chr(0xfeff);
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
