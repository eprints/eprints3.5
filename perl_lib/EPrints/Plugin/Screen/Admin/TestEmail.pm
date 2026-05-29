=head1 NAME

EPrints::Plugin::Screen::Admin::TestEmail

=cut

package EPrints::Plugin::Screen::Admin::TestEmail;

use EPrints::Plugin::Screen::Admin;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ test_email /]; 
		
	$self->{appears} = [
		{ 
			place => "admin_actions_system", 
			position => 1500, 
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/test_email" );
}

sub allow_test_email
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub action_test_email
{
        my( $self ) = @_;

        my $session = $self->{session};

        my @emails = split(/[, \s\/]+/ ,$session->param( "requester_email" ) );

        unless( @emails )
        {
                $self->{processor}->add_message( "error", $self->html_phrase( "no_email" ) );
                return;
        }

        my $mail = $session->make_element( "mail" );
        $mail->appendChild( $self->html_phrase( "test_mail" ));

        for my $email (@emails) {
		unless( EPrints::Utils::validate_email( $email ) ) 
		{ 
			$self->{processor}->add_message( "error", $session->html_phrase( "general:bad_email", email => $session->make_text( $email ) ) ); 
			next;
 		} 
                my $rc = EPrints::Email::send_mail(
                        session => $session,
                        langid => $session->get_langid,
                        to_email => $email,
                        subject => $self->phrase( "test_mail_subject" ),
                        message => $mail,
                        sig => $session->html_phrase( "mail_sig" )
                );

                if( !$rc )
                {
                        $self->{processor}->add_message( "error",
                                $self->html_phrase( "mail_failed",
                                        requester => $session->make_text( $email )
                                 ) );
                }
                else
                {
                        $self->{processor}->add_message( "message",
                                $self->html_phrase( "mail_sent",
                                        requester => $session->make_text( $email )
                                ) );
                }

        }
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my( $html , $table , $p , $span );
	
	$html = $session->make_doc_fragment;

	$html->appendChild( $self->html_phrase( "preamble" ) );

	my $form = $session->render_input_form(
		fields => [
			$session->dataset( "request" )->get_field( "requester_email" ),
		],
		show_names => 1,
		show_help => 1,
		buttons => { test_email => $self->phrase( "send" ) },
	);

	$html->appendChild( $form );
	$form->appendChild( $session->render_hidden_field( "screen", $self->{processor}->{screenid} ) );

	return $html;
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
