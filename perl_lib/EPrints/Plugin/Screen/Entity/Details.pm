=head1 NAME

EPrints::Plugin::Screen::Entity::Details

=cut

package EPrints::Plugin::Screen::Entity::Details;

our @ISA = ( 'EPrints::Plugin::Screen::Entity' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "entity_view_tabs",
			position => 200,
		},
	];

	my $session = $self->{session};
	if( $session && $session->get_online )
	{
		$self->{title} = $session->make_element( "span" );
		$self->{title}->appendChild( $self->SUPER::render_tab_title );
	}

	return $self;
}

sub DESTROY
{
	my( $self ) = @_;

	if( $self->{title} )
	{
		$self->{session}->xml->dispose( $self->{title} );
	}
}

sub render_tab_title
{
	my( $self ) = @_;

	# Return a clone otherwise the DESTROY above will double-dispose of this
	# element when it is disposed by whatever called us
	return $self->{session}->xml->clone( $self->{title} );
}

sub can_be_viewed
{
	my( $self ) = @_;
	
	return $self->allow( $self->{processor}->{entity}->get_dataset_id . "/details" );
}

sub _render_name_maybe_with_link
{
	my( $self, $entity, $field ) = @_;

	my $r_name = $field->render_name( $entity->{session} );

	return $r_name if !$self->edit_ok;

	my $name = $field->get_name;
	my $stage = $self->_find_stage( $entity, $name );

	return $r_name if( !defined $stage );

	my $url = "?dataset=".$entity->get_dataset_id."&dataobj=".$entity->get_id."&screen=".$self->edit_screen_id."&stage=$stage#$name";
	my $link = $entity->{session}->render_link( $url );
	$link->setAttribute( title => $self->phrase( "edit_field_link",
			field => $self->{session}->xhtml->to_text_dump( $r_name )
		) );
	$link->appendChild( $r_name );
	return $link;
}

sub edit_screen_id { return "Workflow::Edit"; }

sub edit_ok
{
	my( $self ) = @_;

	return $self->{edit_ok};
}


sub _find_stage
{
	my( $self, $entity, $name ) = @_;

	my $workflow = $self->workflow;

	return $workflow->{field_stages}->{$name};
}

sub render
{
	my( $self ) = @_;

	my $entity = $self->{processor}->{entity};
	my $session = $entity->{session};
	my $workflow = $self->workflow;

	my $page = $session->make_doc_fragment;

	$self->{edit_ok} = $self->allow( $entity->get_dataset_id . "/edit" );

	my %stages;
	foreach my $stage ("", keys %{$workflow->{stages}})
	{
		$stages{$stage} = {
			count => 0,
			rows => [],
			unspec => $session->make_doc_fragment,
		};
	}

	my @fields = $entity->get_dataset->get_fields;
	my $field_orders = $workflow->{stages_field_orders};
	my $rowshash = {};
	my $unspechash = {};

	# Organise fields into stages
	foreach my $field ( @fields )
	{
		next unless( $field->get_property( "show_in_html" ) );

		my $name = $field->get_name();

		my $stage = $self->_find_stage( $entity, $name );
		$stage = "" if !defined $stage;

		$rowshash->{$stage} ||= {};
		$unspechash->{$stage} ||= {};
		$stages{$stage}->{count}++;

		if( $entity->is_set( $name ) )
		{
			if( !$field->isa( "EPrints::MetaField::Subobject" ) )
			{
				if ( $stage )
				{
					$rowshash->{$stage}->{$field_orders->{$stage}->{$name}} = $name
				}
				else
				{
					$rowshash->{$stage}->{scalar keys %{$rowshash->{$stage}}} = $name;
				}
			}
		}
		else
		{
			if ( $stage )
			{
				$unspechash->{$stage}->{$field_orders->{$stage}->{$name}} = $name;
			}
			else
			{	
				$unspechash->{$stage}->{scalar keys %{$unspechash->{$stage}}} = $name;
			}
		}
	}

	# Organise fields in each stage
	foreach my $stage ( keys %stages )
	{
		my $rows = $stages{$stage}->{rows};
		my $unspec = $stages{$stage}->{unspec};
		foreach my $pos ( sort { $a <=> $b } keys %{$rowshash->{$stage}} ) 
		{
			my $fieldname = $rowshash->{$stage}->{$pos};
			my $field = $entity->get_dataset->get_field( $fieldname );
			my $r_name = $self->_render_name_maybe_with_link( $entity, $field );
			push @$rows, $session->render_row( 
				$r_name,
				$entity->render_value( $fieldname, 1 ) 
			);
		}
		foreach my $pos ( sort { $a <=> $b } keys %{$unspechash->{$stage}} )
		{
			my $fieldname = $unspechash->{$stage}->{$pos};
			my $field = $entity->get_dataset->get_field( $fieldname );
			my $r_name = $self->_render_name_maybe_with_link( $entity, $field );
			if( $unspec->hasChildNodes )
			{
				$unspec->appendChild( $session->make_text( ", " ) );
			}
			$unspec->appendChild( $r_name );
		}
	}

	my $has_problems = 0;

	my $edit_screen = $session->plugin(
		"Screen::".$self->edit_screen_id,
		processor => $self->{processor} );

	my $table = $session->make_element( "table",
			border => "0",
			cellpadding => "3" );
	$page->appendChild( $table );

	foreach my $stage_id ($self->workflow->get_stage_ids, "")
	{
		my $unspec = $stages{$stage_id}->{unspec};
		next if $stages{$stage_id}->{count} == 0;

		my $stage = $self->workflow->get_stage( $stage_id );

		my( $tr, $th, $td );

		my $rows = $stages{$stage_id}->{rows};

		my $url = URI->new( $session->current_url );
		$url->query_form(
			screen => $self->edit_screen_id,
			dataset => $entity->get_dataset_id,
			dataobj => $entity->id,
			stage => $stage_id
		);

		$tr = $session->make_element( "tr" );
		$table->appendChild( $tr );
		$th = $session->make_element( "th", colspan => 2, class => "ep_title_row", role => "banner" );

		$tr->appendChild( $th );

		if( $stage_id eq "" )
		{
			$th->appendChild( $self->html_phrase( "other" ) );
		}
		else
		{
			my $title = $session->html_phrase( "metapage_title_$stage_id" );
			my $table_inner = $session->make_element( "div", class=>'ep_title_row_inner' );
			my $tr_inner = $session->make_element( "div" );
			my $td_inner_1 = $session->make_element( "div" );
			$th->appendChild( $table_inner );
			$table_inner->appendChild( $tr_inner );
			$tr_inner->appendChild( $td_inner_1 );
			$td_inner_1->appendChild( $title );
			if( $self->edit_ok )
			{
				my $td_inner_2  = $session->make_element( "div" );
				$tr_inner->appendChild( $td_inner_2 );
				$td_inner_2->appendChild( $self->render_edit_button( $stage_id ) );
			}
		}

		if( $stage_id ne "" )
		{
			$tr = $session->make_element( "tr" );
			$table->appendChild( $tr );
			$td = $session->make_element( "td", colspan => 2 );
			$tr->appendChild( $td );
			my @problems = $stage->validate( $self->{processor} );
			if( @problems )
			{
				$has_problems = 1;
				$td->appendChild(
					$self->render_stage_warnings( $stage, @problems ) );
			}
		}

		foreach $tr (@$rows)
		{
			$table->appendChild( $tr );
		}

		if( $stage_id ne "" && $unspec->hasChildNodes )
		{
			$table->appendChild( $session->render_row(
				$session->html_phrase( "lib/dataobj:unspecified" ),
				$unspec ) );
		}

		$tr = $session->make_element( "tr" );
		$table->appendChild( $tr );
		$td = $session->make_element( "td", colspan => 2, style=>'height: 1em' );
		$tr->appendChild( $td );
	}

	if( $has_problems )
	{
		my $span = $self->{title};
		$span->setAttribute( style => "padding-left: 20px; background: url('".$session->current_url( path => "static", "style/images/warning-icon.png" )."') no-repeat;" );
	}

	return $page;
}

sub render_edit_button
{
	my( $self, $stage ) = @_;

	my $session = $self->{session};

	my $div = $session->make_element( "div" );

	local $self->{processor}->{stage} = $stage;

	my $screen = $session->plugin( "Screen::".$self->edit_screen_id,
			processor => $self->{processor},
		);
	return $div if !defined $screen; # No Edit screen plugin available

	my $button = $self->render_action_button({
		screen => $screen,
		screen_id => "Screen::".$self->edit_screen_id,
		hidden => { dataset => $self->{processor}->{datasetid}, dataobj => $self->{processor}->{entityid}, stage => $self->{processor}->{stage} },
		idsuffix => "stage_" . $stage,
	});
	$div->appendChild( $button );

	return $div;
}

sub render_stage_warnings
{
	my( $self, $stage, @problems ) = @_;

	my $session = $self->{session};

	my $ul = $session->make_element( "ul" );
	foreach my $problem ( @problems )
	{
		my $li = $session->make_element( "li" );
		$li->appendChild( $problem );
		$ul->appendChild( $li );
	}
	$self->workflow->link_problem_xhtml( $ul, $self->edit_screen_id, $stage );

	return $session->render_message( "warning", $ul );
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.entitys.org/entitys-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.entitys.org/>.

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

