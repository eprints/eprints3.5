=head1 NAME

EPrints::Plugin::Screen::EPrint::ShowLock

=cut

package EPrints::Plugin::Screen::EPrint::ShowLock;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "locked.png";
	$self->{appears} = [
		{
			place => "eprint_item_actions",
			position => -100,
		},
		{
			place => "eprint_review_actions",
			position => -100,
		},
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless defined $self->{processor}->{eprint};
	return 0 if $self->could_obtain_eprint_lock;
	return 1 if $self->{processor}->{eprint}->is_locked;

	return 0;
}

sub render_title
{
	my( $self ) = @_;

	return $self->{processor}->{eprint}->render_value( "edit_lock_user" );
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $eprint = $self->{processor}->{eprint};

	my $page = $session->make_doc_fragment;

	$page->appendChild( $self->render_action_list_bar( "lock_tools", ['eprintid'] ) );

	my $since = $eprint->get_value( "edit_lock_since" ); 
	my $until = $eprint->get_value( "edit_lock_until" ); 

	$page->appendChild( $self->html_phrase( "item_locked",
		locked_by => $eprint->render_value( "edit_lock_user" ),
		locked_since => $session->make_text( EPrints::Time::human_time( $since ) ),
		locked_until => $session->make_text( EPrints::Time::human_time( $until ) ),
		locked_remaining => $session->make_text( $until - time ), ));

	return $page;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
