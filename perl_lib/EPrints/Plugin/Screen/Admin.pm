=head1 NAME

EPrints::Plugin::Screen::Admin

=cut

package EPrints::Plugin::Screen::Admin;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{
			place => "key_tools",
			position => 1000,
		},
	];
	$self->{action_lists} = [qw(
		admin_actions_editorial
		admin_actions_system
		admin_actions_config
		admin_actions
	)];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;
	
	return 0 unless defined $self->{session}->current_user;
	foreach my $list_id ( @{$self->param( "action_lists" )} )
	{
		return 1 if scalar $self->action_list( $list_id );
	}
	return 0;
}

sub render
{
	my( $self ) = @_;

	my $lists = [];

	foreach my $list_id ( @{$self->param( "action_lists" )} )
	{
		next unless scalar $self->action_list( $list_id );

		push @$lists, {
			list_id => $list_id,
			label_phrase_id => $self->html_phrase_id( $list_id ),
			content => $self->render_action_list( $list_id ),
		};
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Admin:render", { item => {
		lists => $lists,
	} } );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
