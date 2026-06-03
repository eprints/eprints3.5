=head1 NAME

EPrints::Plugin::Screen::EPrint::Actions

=cut

package EPrints::Plugin::Screen::EPrint::Actions;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_view_tabs",
			position => 300,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless
		scalar $self->action_list( "eprint_actions" )
		|| scalar $self->action_list( "eprint_editor_actions" );

	return $self->who_filter;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $user = $session->current_user;
	my $staff = $user->is_staff;
	if ( !$staff && $session->config( 'export', 'staff_check' ) )
	{
		$staff = &{$session->config( 'export', 'staff_check' )}( $session, $user );
	}

	my $frag = $session->make_doc_fragment;
	my $table = $session->make_element( "table" );
	$frag->appendChild( $table );
	my( $contents, $tr, $th, $td );

	$contents = $self->render_action_list( "eprint_actions", ['eprintid'] );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild( $contents );
	}

	$contents = $self->render_action_list( "eprint_editor_actions", ['eprintid'] );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$th = $tr->appendChild( $session->make_element( "th", class => "ep_title_row", role => "banner" ) );
		$th->appendChild( $session->html_phrase( "Plugin/Screen/EPrint/Actions/Editor:title" ) );

		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild( $contents );
	}

	$contents = $self->{processor}->{eprint}->render_export_bar( $staff );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$th = $tr->appendChild( $session->make_element( "th", class => "ep_title_row", role => "banner" ) );
		$th->appendChild( $session->html_phrase( "Plugin/Screen/EPrint/Export:title" ) );

		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild(
			$session->make_element( "div", class => "ep_block" )
		)->appendChild(
			$contents
		);
	}

	return $frag;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
