=head1 NAME

EPrints::Plugin::Screen::Login::Internal

=cut

package EPrints::Plugin::Screen::Login::Internal;

@ISA = qw( EPrints::Plugin::Screen::Login EPrints::Plugin::Screen::Register );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{
			place => "login_tabs",
			position => 100,
		},
	];

	return $self;
}

sub render
{
	my( $self, %bits ) = @_;

	my $repo = $self->{repository};

	my $op1;
	my $op2;

	$bits{log_in_until} = $repo->make_element( "select", name=>"login_log_in_until" );
	$op1 = $repo->make_element( "option", value=>"until_close", selected=>"selected" );
	$op1->appendChild( $repo->html_phrase( "cgi/login:until_close" ) );
	$op2 = $repo->make_element( "option", value=>"forever" );
	$op2->appendChild( $repo->html_phrase( "cgi/login:forever" ) );
	$bits{log_in_until}->appendChild( $op1 );
	$bits{log_in_until}->appendChild( $op2 );
	
	$bits{bind_to_ip} = $repo->make_element( "select", name=>"login_log_in_until" );
	$op1 = $repo->make_element( "option", value=>"bind", selected=>"selected" );
	$op1->appendChild( $repo->html_phrase( "cgi/login:bind" ) );
	$op2 = $repo->make_element( "option", value=>"dont_bind" );
	$op2->appendChild( $repo->html_phrase( "cgi/login:dont_bind" ) );
	$bits{bind_to_ip}->appendChild( $op1 );
	$bits{bind_to_ip}->appendChild( $op2 );

	my $reset_ok =  $repo->get_repository->get_conf(
				"allow_reset_password");
	if( $reset_ok ) 
	{
		$bits{reset_link} = $repo->html_phrase(
					"cgi/login:reset_link" );
	}
	else
	{
		$bits{reset_link} = $repo->make_doc_fragment;
	}
	
	$bits{problems} = $repo->make_doc_fragment;
	$bits{input_username} = $repo->render_input_field(
			class => "ep_form_text",
			id => 'login_username',
			name => 'login_username' );

	$bits{input_password} = $repo->render_input_field(
			class => "ep_form_text",
			id => 'login_password',
			name => 'login_password',
			type => "password" );

	my $title = $self->render_title;
	$bits{login_button} = $repo->render_button(
			name => "_action_login",
			value => $repo->xhtml->to_text_dump( $title ),
			class => 'ep_form_action_button',
			role => "button" );
	$repo->xml->dispose( $title );

	my $form = $repo->render_form( "POST" );

	$form->appendChild( $self->render_hidden_bits );
	$form->appendChild( $repo->html_phrase( "cgi/login:page_layout", %bits ) );

	my $script = $repo->make_javascript( 'document.getElementById("login_username").focus()' );
	$form->appendChild( $script );

	return $form;
}

sub action_login
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{repository};

	$processor->{screenid} = 'Login';

	my $username = $repo->param( "login_username" );
	my $password = $repo->param( "login_password" );

	my $real_username = $repo->valid_login( $username, $password );

	if( defined $username && !defined $real_username )
	{
		my $user = $repo->user_by_username( $username );
		if ( defined $user && $user->get_value( "unlocktime" ) )
		{
			my $unlocktime = $repo->make_text( EPrints::Time::human_time( $user->get_value( "unlocktime" ) ) );
			$processor->add_message( "error", $repo->html_phrase( "cgi/login:locked", unlocktime=>$unlocktime ) );
			EPrints::Plugin::Screen::Login::log_login_attempt( $repo, $username, $password, 'locked' );
		}
		elsif( defined $user )
		{
			$processor->add_message( "error", $repo->html_phrase( "cgi/login:failed" ) );
			EPrints::Plugin::Screen::Login::log_login_attempt( $repo, $username, $password, 'invalid' );
		}
		else
		{
			$processor->add_message( "error", $repo->html_phrase( "cgi/login:failed" ) );
			EPrints::Plugin::Screen::Login::log_login_attempt( $repo, $username, $password, 'missing' );
		}
		return;
	}

	$self->{processor}->{username} = $real_username;

	$self->SUPER::action_login;

	return $self->finished;
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

