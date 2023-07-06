=head1 NAME

EPrints::Plugin::Screen::Workflow::View

=cut

package EPrints::Plugin::Screen::Workflow::View;

@ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_view.png";

	$self->{appears} = [
		{
			place => "dataobj_actions",
			position => 200,
		},
	];

	$self->{actions} = [qw/ /];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( $self->{processor}->{dataset}->id."/view" );
}

sub wishes_to_export { shift->{repository}->param( "ajax" ) }

sub export_mime_type { "text/html;charset=utf-8" }

sub export
{
	my( $self ) = @_;

	my $dataset = $self->{processor}->{dataset};

	my $id_prefix = "ep_workflow_views";

	my $current = $self->{session}->param( "${id_prefix}_current" );
	$current = 0 if !defined $current;

	my @items = (
		$self->list_items( "dataobj_view_tabs", filter => 0 ),
		$self->list_items( "dataobj_".$dataset->id."_view_tabs", filter => 0 ),
	);

	my @screens;
	foreach my $item ( @items )
	{
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );
		push @screens, $item->{screen};
	}

	my $content = $screens[$current]->render;
	binmode(STDOUT, ":utf8");
	print $self->{repository}->xhtml->to_xhtml( $content );
	$self->{repository}->xml->dispose( $content );
}

sub render_title
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $screen = $self->view_screen();

	my $dataset = $self->{processor}->{dataset};
	my $dataobj = $self->{processor}->{dataobj};

	my $priv = $dataset->id . "/view";
	my $url = URI->new( $session->current_url );

	$url->query_form(
		screen => $self->listing_screen,
		dataset => $dataset->id
	);

	return $session->template_phrase( "view:EPrints/Plugin/Screen/Workflow:render_title", { item => {
		can_view_dataset => $self->EPrints::Plugin::Screen::allow( $priv ),
		title_phrase_id => $self->html_phrase_id( "page_title" ),
		name => $dataset->render_name( $session ),
		description => $dataobj->render_description(),
		dataset_url => $url,
	} } );
}

sub render
{
	my( $self ) = @_;

	my $dataset = $self->{processor}->{dataset};

	# current view to show
	my $view = $self->{session}->param( "view" );
	if( defined $view )
	{
		$view = "Screen::$view";
	}

	my $id_prefix = "ep_workflow_views";

	my $current = $self->{session}->param( "${id_prefix}_current" );
	$current = 0 if !defined $current;

	my @items = (
		$self->list_items( "dataobj_view_tabs", filter => 0 ),
		$self->list_items( "dataobj_".$dataset->id."_view_tabs", filter => 0 ),
		);

	my @screens;
	foreach my $item (@items)
	{
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );
		push @screens, $item->{screen};
	}

	my $tabs;

	if( @screens )
	{
		my @labels;
		my @contents;
		my @expensive;

		for(my $i = 0; $i < @screens; ++$i)
		{
			my $screen = $screens[$i];
			my $rtt = $screen->render_tab_title;
			push @labels, ( $rtt ) ? $rtt : $screen;
			push @expensive, $i if $screen->{expensive};
			if( $screen->{expensive} && $i != $current )
			{
				push @contents, $self->{session}->html_phrase(
					"cgi/users/edit_eprint:loading"
				);
			}
			else
			{
				push @contents, $screen->render;
			}
		}

		$tabs = $self->{session}->xhtml->tabs(
			\@labels,
			\@contents,
			basename => $id_prefix,
			current => $current,
			expensive => \@expensive,
			);
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Workflow:render", { item => {
		status => $self->render_status,
		buttons => $self->render_common_action_buttons,
		tabs => $tabs,
	} } );
}

sub render_status
{
	my( $self ) = @_;

	my $dataobj = $self->{processor}->{dataobj};

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Workflow:render_status", { item => {
		url => $dataobj->uri
	} } );
}

sub render_common_action_buttons
{
	my( $self ) = @_;

	my $datasetid = $self->{processor}->{dataset}->id;

	return $self->render_action_list_bar( ["${datasetid}_view_actions", "dataobj_view_actions"], {
					dataset => $datasetid,
					dataobj => $self->{processor}->{dataobj}->id,
				} );
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

