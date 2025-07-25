=head1 NAME

EPrints::Plugin::Screen::Login

=cut

package EPrints::Plugin::Screen::Login;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
# See cfg.d/dynamic_template.pl
#		{
#			place => "key_tools",
#			position => 100,
#		},
	];
	$self->{actions} = [qw( login )];

	return $self;
}

sub allow_login { 1 }
sub can_be_viewed { 1 }

# also used by Screen::Register
sub finished
{
	my( $self, $uri ) = @_;

	my $repo = $self->{repository};

	my $user = $self->{processor}->{user};

	if( !$uri )
	{
		$uri = URI->new( $repo->current_url( host => 1 ) );
		$uri->query($repo->param( "login_params" ) );
	}
	else
	{
		$uri = URI->new( $uri );
	}

	if( defined $user )
	{
		$uri->query_form(
			$uri->query_form,
			login_check => 1
			);
		# Create a login ticket and log the user in
		EPrints::DataObj::LoginTicket->expire_all( $repo );
		my $loginticket = $repo->dataset( "loginticket" )->create_dataobj({
			userid => $user->id,
		});
		$loginticket->set_cookies();
		log_login_attempt( $repo, $user->get_value( 'username' ), '', 'success', $loginticket->get_value( 'securecode' ) );
	}

	$repo->redirect( "$uri" );
	exit(0);
}

sub render_title
{
	my( $self ) = @_;

	if( defined( my $user = $self->{session}->current_user ) )
	{
		my $item = {
			user => $user->render_citation( 'login' ),
        	};

		return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Login:render_title", { item => $item });
	}
	else
	{
		return $self->SUPER::render_title;
	}
}

sub render_action_link
{
	my( $self, %opts ) = @_;

	if( defined $self->{session}->current_user )
	{
		return $self->render_title;
	}
	else
	{
		$opts{uri} = $self->{session}->config( "http_cgiroot" ) . "/users/home";
		return $self->SUPER::render_action_link( %opts );
	}
}

sub action_login
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{repository};
	my $r = $repo->get_request;

	my $username = $self->{processor}->{username};

	return if !defined $username;

	my $user = $repo->user_by_username( $username );
	if( !defined $user )
	{
		$processor->add_message( "error", $repo->html_phrase( "cgi/login:failed" ) );
		log_login_attempt( $repo, $username, $repo->param( "login_password" ), 'missing' );
		return;
	}

	$self->{processor}->{user} = $user;
}

sub render
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $r = $repo->get_request;

	# catch infinite recursion on tab rendering
	return $xml->create_document_fragment if ref($self) ne __PACKAGE__;

	$r->status( 401 );
	$r->custom_response( 401, '' ); # disable the normal error document

	my $page = $repo->make_doc_fragment;

	my @tabs = map { $_->{screen} } $self->list_items( "login_tabs" );

	my $show = $self->{processor}->{show};
	$show = '' if !defined $show;
	my $current = 0;
	for($current = 0; $current < @tabs; ++$current)
	{
		last if $tabs[$current]->get_subtype eq $show;
	}
	$current = 0 if $current == @tabs;

	if( @tabs == 1 )
	{
		$page->appendChild( $tabs[0]->render );
	}
	elsif( @tabs )
	{
		$page->appendChild( $repo->xhtml->tabs(
			[map { $_->render_title } @tabs],
			[map { $_->render } @tabs],
			current => $current
			) );
	}


	my @tools = map { $_->{screen} } $self->list_items( "login_tools" );

	my $div = $repo->make_element( "div", class => "ep_block ep_login_tools" );

	my $internal;
	foreach my $tool ( @tools )
	{
		$div->appendChild( $tool->render_action_link );
	}
	$page->appendChild( $div );


	return $page;
}

sub hidden_bits
{
	my( $self ) = @_;

	my $repo = $self->{repository};

	my @params = $self->SUPER::hidden_bits;

	my $login_params = $repo->param( "login_params" );
	if( !defined $login_params )
	{
		$login_params = $repo->get_request->args;
		$login_params = "" if !defined $login_params;
	}
	push @params, login_params => $login_params;

	my $target = $repo->param( "target" );
	if( $target )
	{
		push @params, target => $target;
	}

	return @params;
}

sub log_login_attempt
{
	my( $repo, $username, $password, $status, $securecode ) = @_;

	return 0 unless $repo->config( 'login_monitoring', 'enabled' );
	my $timestamp = EPrints::Time::get_iso_timestamp();
	my $year_month = substr($timestamp,0,4) . '/'. substr($timestamp,5,2); 
	my $day = substr($timestamp,8,2);
	my $logdir = $repo->config('variables_path') . "/login_attempts/$year_month/";
	my $logfile = "$logdir$day.csv";
	my $logfile_exists = -e $logfile;
	EPrints::Platform::mkdir( $logdir ) unless $logfile_exists;
	open( my $fh, '>>', $logfile );
	if ( defined $repo->config( 'login_monitoring', 'fields' ) )
	{
		my $fields = join( ',', @{ $repo->config( 'login_monitoring', 'fields' ) } );
		print $fh "$fields\n" unless $logfile_exists;
	}
	if ( defined $repo->config( 'login_monitoring', 'function' ) )
	{
		my $func = $repo->config( 'login_monitoring', 'function' );
		return $func->( $fh, $repo, $timestamp, $username, $password, $status, $securecode );
	}
	else {
		my $fields = "timestamp,username,password_length,ip,user_agent,target,status,userid,securecode";
		print $fh "$fields\n" unless $logfile_exists || defined $repo->config( 'login_monitoring', 'fields' );
		my $password_length = length( $password );
		my $userid = '';
		if ( $status eq "success" )
		{
			$userid = $repo->user_by_username( $username )->id;
			$password_length = '';
		}	
		print $fh "\"$timestamp\",\"$username\",\"$password_length\",\"".$repo->remote_ip."\",\"".$repo->get_request->headers_in->{ "User-Agent" }."\",\"".$repo->param( "target" )."\",\"$status\",\"$userid\",\"$securecode\"\n";
		close( $fh );
	}
	return 1;
}

1;

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

