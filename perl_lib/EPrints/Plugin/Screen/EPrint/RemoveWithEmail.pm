=head1 NAME

EPrints::Plugin::Screen::EPrint::RemoveWithEmail

=cut

package EPrints::Plugin::Screen::EPrint::RemoveWithEmail;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_reject.png";
	$self->{appears} = [
		{
			place => "eprint_editor_actions",
			position => 300,
		},
		{
			place => "eprint_actions_bar_buffer", 
			position => 300,
		},
		{
			place => "eprint_review_actions",
			position => 400,
		},
		{
                        place => "eprint_actions_bar_archive",
                        position => 1100,
                },
	];

	$self->{actions} = [qw/ send cancel /];

	return $self;
}

sub obtain_lock
{
	my( $self ) = @_;

	return $self->{processor}->{eprint}->could_obtain_lock( $self->{session}->current_user );
}


sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless defined $self->{processor}->{eprint};
	return 0 if( !defined $self->{processor}->{eprint}->get_user );
	return 0 unless $self->could_obtain_eprint_lock;

	# Do not allow items that are or have once been in the live archive to be removed unless the user has an extra special permission.
	return 0 if $self->{processor}->{eprint}->is_set( 'datestamp' ) && !$self->allow( "eprint/remove_once_archived" );         

	return $self->allow( "eprint/remove_with_email" );
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

	if( $eprint->is_set( "datestamp" ) )
        {
                $page->appendChild(
                        $self->{session}->html_phrase(
                                "cgi/users/edit_eprint:remove_once_archived" ) );
        }

	
	$page->appendChild( 
		$self->{session}->html_phrase( 
			"cgi/users/edit_eprint:remove_form_intro" ) );

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
		
		my $edit_link = $self->{session}->make_element( "a", href=>"#", role=>"button", onclick => "EPJS_toggle('ep_mail_reason_fixed',true,'block');EPJS_toggle('ep_mail_reason_edit',false,'block');\$('ep_mail_reason_edit').focus(); \$('ep_mail_reason_edit').select(); return false", );
		$reason_static->appendChild( $self->{session}->html_phrase( "mail_edit_click",
			edit_link => $edit_link,
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

		# remove any markup:
		my $title = $self->{session}->make_text( 
			EPrints::Utils::tree_to_utf8( 
				$eprint->render_description() ) );
		
		my $phraseid;
		if( $eprint->get_dataset->id eq "inbox" )
		{
			$phraseid = "mail_delete_body.inbox";
		}
		else
		{
			$phraseid = "mail_delete_body";
		}
		
		my $content = $self->{session}->html_phrase(
			$phraseid,	
			title => $title,
			reason => $reason );

		my $body = $self->{session}->html_phrase(
			"mail_body",
			content => $content );

		my $to_user = $eprint->get_user();
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
		"send" => $self->{session}->phrase( "priv:action/eprint/remove_with_email" ),
		"cancel" => $self->{session}->phrase( "cgi/users/edit_eprint:action_cancel" ),
 	) );

	return( $page );
}	


sub action_send
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $user = $eprint->get_user();
	# We can't bounce it if there's no user associated 

	$self->{processor}->{screenid} = "Review";

	if( !$eprint->remove )
	{
		my $db_error = $self->{session}->get_database->error;
		$self->{session}->get_repository->log( "DB error removing EPrint ".$eprint->get_value( "eprintid" ).": $db_error" );
		$self->{processor}->add_message( "message", $self->html_phrase( "item_not_removed" ) );
		$self->{processor}->{screenid} = "FirstTool";
		return;
	}

	$self->{processor}->add_message( "message", $self->html_phrase( "item_removed" ) ); 
	
	# Successfully removed, mail the user with the reason

	my $content;
	my $mail_ok = do {
		# change language temporarily to the user's language
		local $self->{session}->{lang} = $user->language();

		my $title = $self->{session}->make_text( 
			EPrints::Utils::tree_to_utf8( 
				$eprint->render_description() ) );
		
		$content = $self->{session}->html_phrase( 
			"mail_delete_body",
			title => $title, 
			reason => EPrints::Extras::render_paras( $self->{session}, "reason", scalar( $self->{session}->param( "reason" ) ) )
		);

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

