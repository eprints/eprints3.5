=head1 NAME

EPrints::Plugin::Export::ListUserEmails

=cut

package EPrints::Plugin::Export::ListUserEmails;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "List of Email Addresses";
	$self->{accept} = [ 'dataobj/user', 'list/user' ];
	$self->{visible} = "staff";
	$self->{suffix} = "text";
	$self->{mimetype} = "text/plain";

	return $self;
}


sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	return "" if $dataobj->is_set( "pin" );
	return "" if !$dataobj->is_set( "email" );

	my $email = $dataobj->get_value( "email" );

	return "$email\n";
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
