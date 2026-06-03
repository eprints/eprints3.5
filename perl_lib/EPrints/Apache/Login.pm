######################################################################
#
# EPrints::Apache::Login
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

EPrints::Apache::Login

=head1 DESCRIPTION

EPrints Login handler.

=head1 METHODS

=cut

package EPrints::Apache::Login;

use strict;

use EPrints;
use EPrints::Apache::AnApache;

######################################################################
=pod

=over 4

=item $rc = EPrints::Apache::Login::handler( $r )

Handler for managing EPrints login requests.

=cut
######################################################################

sub handler
{
	my( $r ) = @_;

	my $session = new EPrints::Session;
	my $problems;

	if( $session->param( "login_check" ) )
	{
		# If this is set, we didn't log in after all!
		$problems = $session->html_phrase( "cgi/login:no_cookies" );
	}

	my $screenid = $session->param( "screen" );
	if( !defined $screenid || $screenid !~ /^Login::/ )
	{
		$screenid = "Login";
	}

	EPrints::ScreenProcessor->process(
		session => $session,
		screenid => $screenid,
		problems => $problems,
	);

	return DONE;
}

1;

######################################################################
=pod

=back

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
