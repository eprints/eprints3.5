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

