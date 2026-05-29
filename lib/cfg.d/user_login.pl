
=pod

# Please see http://wiki.eprints.org/w/User_login.pl
$c->{check_user_password} = sub {
	my( $repo, $username, $password ) = @_;

	... check whether $password is ok

	return $ok ? $username : undef;
};

=cut

# Maximum time (in seconds) before a user must log in again
# $c->{user_session_timeout} = undef; 

# Time (in seconds) to allow between user actions before logging them out
# $c->{user_inactivity_timeout} = 86400 * 7;

# Set the cookie expiry time
# $c->{user_cookie_timeout} = undef; # e.g. "+3d" for 3 days



# Additional restrictions to allow parts of a repository to be limited to logged in users
# see Rewrite.pm for implementation

# restrict access to abstract/summary pages
# $c->{login_required_for_eprints}->{enable} = 1;

# restrict access to view pages
# $c->{login_required_for_views}->{enable} = 1;

# restrict access to static pages
# $c->{login_required_for_static}->{enable} = 1;
# still allow access to homepage and all resources the homepage requires when a vanilla installation
# $c->{login_required_for_static}->{exceptions} = [ "/", "/favicon.ico", "/images/.*", "/style/images/.*" ];

# restrict access to cgi pages
# $c->{login_required_for_cgi}->{enable} = 1;
# can't restrict access to the login cgi page
# $c->{login_required_for_cgi}->{exceptions} = [ "users/login" ];

# login page to redirct users to
# $c->{login_required_url} = "/cgi/users/login";



=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
