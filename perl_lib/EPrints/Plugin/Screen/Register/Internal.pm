=head1 NAME

EPrints::Plugin::Screen::Register::Internal

=cut

package EPrints::Plugin::Screen::Register::Internal;

@ISA = qw( EPrints::Plugin::Screen::Register );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{
			place => "register_tabs",
			position => 100,
		},
	];

	return $self;
}

sub action_register
{
	my( $self ) = @_;

	return if !$self->SUPER::action_register;

	my $processor = $self->{processor};
	my $repo = $self->{repository};

	my $dataset = $repo->dataset( "user" );

	my $item = $processor->{item};

	my $email;
	if( $item->is_set( "newemail" ) )
	{
		$email = $item->value( "newemail" );

		# registering, so don't send a "new email address" email
		$item->set_value( "email", $email );
		$item->set_value( "newemail", undef );
	}
	else
	{
		$email = $item->value( "email" );
	}

	if( $processor->{min} )
	{
		$item->set_value( "username", $email );
	}

	my $username = $item->value( "username" );

	if( defined EPrints::DataObj::User::user_with_email( $repo, $email ) )
	{
		$processor->add_message( "error", $repo->html_phrase(
			"cgi/register:email_exists", 
			email=>$repo->make_text( $email ) ) );
		return;
	}

	if( $repo->can_call( "check_registration_email" ) )
	{
		if( !$repo->call( "check_registration_email", $repo, $email ) )
		{
			$processor->add_message( "error", $repo->html_phrase(
				"cgi/register:email_denied",
				email=>$repo->make_text( $email ) ) );
			return;
		}
	} 

	if( defined EPrints::DataObj::User::user_with_username( $repo, $username ) )
	{
		$processor->add_message( "error", $repo->html_phrase(
			"cgi/register:username_exists", 
			username=>$repo->make_text( $username ) ) );
		return;
	}

	if ( defined $repo->config( "max_account_requests" ) && defined $repo->config( "max_account_requests_minutes" )  )
        {
                my $minutes = $repo->config( "max_account_requests_minutes" );
                if ( $minutes > 0 )
                {
                        my $since = time() - 60 * $minutes;
                        my $users = $dataset->search( filters => [{
				meta_fields => [qw( joined )], value => EPrints::Time::iso_datetime( $since ) . "-",
  			}]);
                        if ( $users->count >= $repo->config( "max_account_requests" ) )
                        {
                                $self->{processor}->add_message( "error", $repo->html_phrase(
                                        "cgi/register:excessive_account_requests",
                                        minutes => $repo->make_text( $minutes )
                                ) );
                                return;
                        }
                }
        }
	
	my $user = $self->register_user( $item->get_data );

	$processor->{user} = $user;

	return 1;
}

sub render
{
	my( $self ) = @_;

	return $self->SUPER::render_workflow();
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
