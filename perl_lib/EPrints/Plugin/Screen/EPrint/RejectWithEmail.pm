=head1 NAME

EPrints::Plugin::Screen::EPrint::RejectWithEmail

=cut

package EPrints::Plugin::Screen::EPrint::RejectWithEmail;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_bounce.png";
	$self->{appears} = [
		{
			place => "eprint_editor_actions",
			position => 200,
		},
		{
			place => "eprint_actions_bar_buffer", 
			position => 200,
		},
		{
			place => "eprint_review_actions",
			position => 300,
		},
	];

	$self->{actions} = [qw/ send cancel /];

	return $self;
}

sub obtain_lock
{
	my( $self ) = @_;

	return $self->could_obtain_eprint_lock;
}


sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless defined $self->{processor}->{eprint};
	return 0 unless $self->could_obtain_eprint_lock;
	return 0 if( $self->{processor}->{eprint}->get_value( "eprint_status" ) eq "inbox" );
	return 0 if( !defined $self->{processor}->{eprint}->get_user );

	return $self->allow( "eprint/reject_with_email" );
}

sub allow_send
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub allow_cancel
{
	my( $self ) = @_;

	return 1;
}

sub action_cancel
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "EPrint::View";
}

sub render
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $user = $eprint->get_user();
	# We can't bounce it if there's no user associated 

	if( !defined $user )
	{
		$self->{session}->render_error( 
			$self->{session}->html_phrase( 
				"cgi/users/edit_eprint:no_user" ),
			"error" );
		return;
	}

	my $page = $self->{session}->make_doc_fragment();

	$page->appendChild( 
		$self->{session}->html_phrase( 
			"cgi/users/edit_eprint:reject_form_intro" ) );
		
	if( $user->is_set( "lang" ) )
	{
		$page->appendChild( 
			$self->{session}->html_phrase(
				"cgi/users/edit_eprint:author_lang_pref", 
				langpref => $user->render_value( "lang" ) ) );
	}

	my $form = $self->render_form;
	
	$page->appendChild( $form );

	my $div = $self->{session}->make_element( "div", class => "ep_form_field_input" );

	do {
		# change language temporarily to the user's language
		local $self->{session}->{lang} = $user->language();

		my $reason = $self->{session}->make_doc_fragment;
		my $reason_label = $self->{session}->make_element( "label", for=>"ep_mail_reason_edit" );
		$reason_label->appendChild( $self->html_phrase( "reason_label" ) );
		$reason_label->appendChild( $self->{session}->make_text( ":" ) );
		$reason->appendChild( $reason_label );
		my $reason_static = $self->{session}->make_element( "div", id=>"ep_mail_reason_fixed",class=>"ep_only_js" );
		$reason_static->appendChild( $self->{session}->html_phrase( "mail_bounce_reason" ) );
		$reason_static->appendChild( $self->{session}->make_text( " " ));	
		
		my $edit_link_a = $self->{session}->make_element( "a", href=>"#", role=>"button", onclick => "EPJS_toggle('ep_mail_reason_fixed',true,'block');EPJS_toggle('ep_mail_reason_edit',false,'block');\$('ep_mail_reason_edit').focus(); \$('ep_mail_reason_edit').select(); return false", );
		$reason_static->appendChild( $self->{session}->html_phrase( "mail_edit_click",
			edit_link => $edit_link_a,
			change_field => $self->html_phrase( "reason_label" ) 
		) ); 
		$reason->appendChild( $reason_static );
		
		my $textarea = $self->{session}->make_element(
			"textarea",
			id => "ep_mail_reason_edit",
			class => "ep_no_js",
			name => "reason",
			rows => 5,
			cols => 60,
			wrap => "virtual" );
		$textarea->appendChild( $self->{session}->html_phrase( "mail_bounce_reason" ) ); 
		$reason->appendChild( $textarea );

		my $body = $self->{session}->html_phrase(
			"mail_body",
			content => $self->render_body( reason => $reason ) );

		my $to_user = $user;
		my $from_desc = $self->{session}->config( 'reply_to_adminemail' ) ?  $self->{session}->html_phrase( "archive_name" ) : $self->{session}->current_user->render_description;

		my $subject = $self->{session}->html_phrase( "cgi/users/edit_eprint:subject_bounce" );

		my $view = $self->{session}->html_phrase(
			"mail_view",
			subject => $subject,
			to => $to_user->render_description,
			from => $from_desc,
			body => $body );

		$div->appendChild( $view );
		
	};

	$form->appendChild( $div );

	$form->appendChild( $self->{session}->render_action_buttons(
		_class => "ep_form_button_bar",
		"send" => $self->{session}->phrase( "priv:action/eprint/reject_with_email" ),
		"cancel" => $self->{session}->phrase( "cgi/users/edit_eprint:action_cancel" ),
 	) );

	return( $page );
}	

sub render_body
{
	my( $self, %parts ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $repo = $self->{session};

	$parts{title} = $repo->make_text(
			EPrints::Utils::tree_to_utf8( $eprint->render_citation() )
		) if !defined $parts{title};
	
	$parts{edit_link} = $repo->render_link( $eprint->get_control_url() )
		if !defined $parts{edit_link};

	$parts{reason} = EPrints::Extras::render_paras( $repo, "reason", scalar( $repo->param( "reason" ) ) )
		if !defined $parts{reason};

	return $repo->html_phrase(
		"mail_bounce_body",
		%parts );
}

sub action_send
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $user = $eprint->get_user();
	# We can't bounce it if there's no user associated 

	$self->{processor}->{screenid} = "EPrint::View";

	if( !$eprint->move_to_inbox )
	{
		$self->{processor}->add_message( 
			"error",
			$self->{session}->html_phrase( 
				"cgi/users/edit_eprint:bord_fail" ) );
	}

	$self->{processor}->add_message( "message",
		$self->{session}->html_phrase( 
			"cgi/users/edit_eprint:status_changed" ) );

	# Successfully transferred, mail the user with the reason

	my $content = $self->render_body;
	my $mail_ok = do {
		# change language temporarily to the user's language
		local $self->{session}->{lang} = $user->language();

		$user->mail(
			"cgi/users/edit_eprint:subject_bounce",
			$content,
			$self->{session}->current_user );
	};
	
	if( !$mail_ok ) 
	{
		$self->{processor}->add_message( "warning",
			$self->{session}->html_phrase( 
				"cgi/users/edit_eprint:mail_fail",
				username => $user->render_value( "username" ),
				email => $user->render_value( "email" ) ) );
		return;
	}

	$self->{processor}->add_message( "message",
		$self->{session}->html_phrase( 
			"cgi/users/edit_eprint:mail_sent" ) );
	$eprint->log_mail_owner( $content );
}


1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE


