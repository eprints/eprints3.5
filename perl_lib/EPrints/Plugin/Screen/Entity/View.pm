=head1 NAME

EPrints::Plugin::Screen::Entity::View

=cut


package EPrints::Plugin::Screen::Entity::View;

use EPrints::Plugin::Screen::Entity;

@ISA = ( 'EPrints::Plugin::Screen::Entity' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_entity.svg";

	$self->{appears} = [];
	foreach my $datasetid ( @{$self->{session}->config( 'entities', 'datasets' )} )
	{
		push @{$self->{appears}}, 
		{
			place => "entity_page_actions",
			position => 100,
		},
		{
			place => $datasetid . "_item_actions",
			position => 800,
		};
	}

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	$self->{processor}->{tab_prefix} = "ep_entity_view";

	$self->SUPER::properties_from;
}

sub wishes_to_export { shift->{repository}->param( "ajax" ) }

sub export_mime_type { "text/html;charset=utf-8" }

sub export
{
	my( $self ) = @_;

	my $id_prefix = $self->{processor}->{tab_prefix};

	my $current = $self->{session}->param( "${id_prefix}_current" );
	$current = 0 if !defined $current;

	my @screens;
	foreach my $item ( $self->list_items( "entity_view_tabs", filter => 0 ) )
	{
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );
		push @screens, $item->{screen};
	}

	local $self->{processor}->{current} = $current;

	my $content = $screens[$current]->render( "${id_prefix}_$current" );
	binmode(STDOUT, ":utf8");
	print $self->{repository}->xhtml->to_xhtml( $content );
	$self->{repository}->xml->dispose( $content );
}

sub register_furniture
{
	my( $self ) = @_;

	my $entity = $self->{processor}->{entity};
	my $user = $self->{session}->current_user;

	return $self->SUPER::register_furniture;
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		$self->SUPER::hidden_bits,
		$self->{processor}->{tab_prefix} . "_current" => $self->{processor}->{current},
	);
}

sub about_to_render 
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "Entity::View";	
}

sub can_be_viewed
{
	my( $self ) = @_;

	my $fn = $self->{session}->get_conf( "entity_access_restrictions_callback" );
	if( defined $fn && ref $fn eq "CODE" )
	{
		my $rv = &{$fn}( $self->{processor}->{entity}, $self->{session}->current_user, "read" );
		return 1 if $rv;
	}

	return $self->allow( $self->{processor}->{dataset}->id . "/view" ) & $self->who_filter;
}

sub render
{
	my( $self ) = @_;

	my $chunk = $self->{session}->make_doc_fragment;

	my $div = $self->{session}->make_element( "div", class => "ep_block" );
	my $buttons = $self->render_common_action_buttons;
	$div->appendChild( $buttons );
	$chunk->appendChild( $div );

	my $id_prefix = $self->{processor}->{tab_prefix};

	my $current = $self->{session}->param( "${id_prefix}_current" );
	$current = 0 if !defined $current;

	my @screens;
	foreach my $item ( $self->list_items( "entity_view_tabs", filter => 0 ) )
	{
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );
		push @screens, $item->{screen};
	}

	my @labels;
	my @contents;
	my @expensive;

	for(my $i = 0; $i < @screens; ++$i)
	{
		# allow hidden_bits to point to the correct tab for local links
		local $self->{processor}->{current} = $i;

		my $screen = $screens[$i];
		my $rtt = $screen->render_tab_title;
		push @labels, ($rtt) ? $rtt : "no title";

		push @expensive, $i if $screen->{expensive};
		if( $screen->{expensive} && $i != $current )
		{
			push @contents, $self->{session}->html_phrase(
				"cgi/users/edit_entity:loading"
			);
		}
		else
		{
			push @contents, $screen->render( "${id_prefix}_$i" );
		}
	}

	$chunk->appendChild( $self->{session}->xhtml->tabs(
		\@labels,
		\@contents,
		basename => $id_prefix,
		current => $current,
		expensive => \@expensive,
		) );

	$chunk->appendChild( $buttons->cloneNode(1) );
	return $chunk;
}

sub render_common_action_buttons
{
	my( $self ) = @_;

	return  $self->render_action_list_bar( "entity_actions_bar", [ 'dataset', 'entity' ] );
}



sub redirect_to_me_url
{
	my( $self ) = @_;

	return defined $self->{processor}->{view} ?
		$self->SUPER::redirect_to_me_url."&view=".$self->{processor}->{view} :
		$self->SUPER::redirect_to_me_url;
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

