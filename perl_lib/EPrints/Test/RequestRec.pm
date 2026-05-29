=head1 NAME

EPrints::Test::RequestRec

=cut

package EPrints::Test::RequestRec;

# fake mod_perl query package

sub new
{
	my( $class, %opts ) = @_;

	return bless \%opts, $class;
}

sub is_initial_req { 1 }

sub uri
{
	my( $self ) = @_;

	return $self->{uri};
}

sub args
{
	my( $self ) = @_;

	return $self->{args};
}

sub pool
{
	my( $self ) = @_;

	return $self->{pool} ||= EPrints::Test::Pool->new();
}

sub filename
{
	my( $self ) = @_;

	$self->{filename} = $_[1] if @_ == 2;

	return $self->{filename};
}

sub dir_config
{
	my( $self, $key ) = @_;

	return $self->{dir_config}->{$key};
}

sub headers_in
{
	my( $self ) = @_;

	return $self->{headers_in} ||= {};
}

sub headers_out
{
	my( $self ) = @_;

	return $self->{headers_out} ||= {};
}

sub custom_response
{
	my( $self, $code, $url ) = @_;
}

sub handler
{
	my( $self, $handler ) = @_;
}

sub set_handlers
{
	my( $self, $handlers ) = @_;
}

package EPrints::Test::Pool;

sub new
{
	my( $class, %opts ) = @_;

	$opts{cleanup} = [];

	return bless \%opts, $class;
}

sub cleanup_register
{
	my( $self, $f, $ctx ) = @_;

	unshift @{$self->{cleanup}}, [$f, $ctx];
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
