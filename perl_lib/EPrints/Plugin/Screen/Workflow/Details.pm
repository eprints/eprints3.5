=head1 NAME

EPrints::Plugin::Screen::Workflow::Details

=cut

package EPrints::Plugin::Screen::Workflow::Details;

@ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "dataobj_view_tabs",
			position => 100,
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

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from;

}

sub can_be_viewed
{
	my( $self ) = @_;
		
	return $self->allow( $self->{processor}->{dataset}->id."/details" );
}

sub _find_stage
{
	my( $self, $name ) = @_;

	return undef if !$self->{processor}->{can_be_edited};

	return undef if !$self->has_workflow();

	my $workflow = $self->workflow;

	return $workflow->{field_stages}->{$name};
}

sub _render_name_maybe_with_link
{
	my( $self, $field ) = @_;

	my $dataset = $self->{processor}->{dataset};
	my $dataobj = $self->{processor}->{dataobj};

	my $name = $field->get_name;
	my $stage = $self->_find_stage( $name );

	my $url;

	if( defined $stage )
	{
		$url = URI->new( $self->{session}->current_url );

		$url->query_form(
			screen => $self->edit_screen,
			dataset => $dataset->id,
			dataobj => $dataobj->id,
			stage => $stage
		);

		$url->fragment( $name );
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Workflow/Details:_render_name_maybe_with_link", { item => {
		name => $field->render_name( $self->{session} ),
		url => $url,
	} } );
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

sub render
{
	my( $self ) = @_;

	my $dataobj = $self->{processor}->{dataobj};
	my $session = $self->{session};
	my $workflow = $self->workflow;

	my $has_problems = 0;

	#$self->{edit_ok} = $self->could_obtain_eprint_lock; # hmm
	my $plugin = $session->plugin( "Screen::" . $self->edit_screen,
		processor => $self->{processor}
	);
	my $edit_ok = $plugin->can_be_viewed;

	my %stages;
	foreach my $stage ("", keys %{$workflow->{stages}})
	{
		$stages{$stage} = {
			count => 0,
			rows => [],
			unspec => [],
		};
	}

	my @fields = $dataobj->dataset->fields;
	my $field_orders = $workflow->{stages_field_orders};
	my $rowshash = {};
	my $unspechash = {};

	# Organise fields into stages
	foreach my $field ( @fields )
	{
		next unless( $field->get_property( "show_in_html" ) );

		my $name = $field->get_name();

		my $stage = $self->_find_stage( $name );
		$stage = "" if !defined $stage;

		$rowshash->{$stage} ||= {};
		$unspechash->{$stage} ||= {};
		$stages{$stage}->{count}++;

		my $r_name = $self->_render_name_maybe_with_link( $field );

		if( $dataobj->is_set( $name ) )
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

	my $sections = [];

    # Organise fields in each stage
    foreach my $stage ( keys %stages )
    {
        my $rows = $stages{$stage}->{rows};
        my $unspec = $stages{$stage}->{unspec};
        foreach my $pos ( sort { $a <=> $b } keys %{$rowshash->{$stage}} )
        {
            my $fieldname = $rowshash->{$stage}->{$pos};
            my $field = $dataobj->get_dataset->get_field( $fieldname );
            my $r_name = $self->_render_name_maybe_with_link( $field );

            my $render_row = $session->render_row(
                $r_name,
                $dataobj->render_value( $fieldname, 1 )
            );

            push @$rows, {
                name => $fieldname,
                render_row => $render_row,
            };

        }
        foreach my $pos ( sort { $a <=> $b } keys %{$unspechash->{$stage}} )
        {
            my $fieldname = $unspechash->{$stage}->{$pos};
            my $field = $dataobj->get_dataset->get_field( $fieldname );
            my $r_name = $self->_render_name_maybe_with_link( $field );

            push @$unspec, {
                name => $fieldname,
                render_name => $r_name,
            };
        }
    }

	foreach my $stage_id ($self->workflow->get_stage_ids, "")
	{
		my $section_info = {
			unspec => [],
			count => $stages{$stage_id}->{count},
			rows => $stages{$stage_id}->{rows},
		};

		my $unspec = $stages{$stage_id}->{unspec};
		next if $stages{$stage_id}->{count} == 0;

		my $stage = $self->workflow->get_stage( $stage_id );

		if( defined $stage )
		{
			my $warnings = $self->render_stage_warnings( $stage );
			my $has_warnings = $warnings->hasChildNodes;

			$section_info->{title} = $stage->render_title();
			$section_info->{warnings} = $warnings;
			$section_info->{has_problems} = $has_warnings;
			$section_info->{unspec} = $unspec;

			if( $edit_ok )
			{
				$section_info->{edit_button} = $self->render_edit_button( $stage );
			}

			if( $has_warnings )
			{
				$has_problems = 1;
			}
		}

		push @$sections, $section_info;
	}

	if( $has_problems )
	{
		my $span = $self->{title};
		$span->setAttribute( style => "padding-left: 20px; background: url('".$session->current_url( path => "static", "style/images/warning-icon.png" )."') no-repeat;" );
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Workflow/Details:render", { item => {
		edit_ok => $edit_ok,
		sections => $sections,
		other_title_phrase => $self->html_phrase_id( "other" ),
	} } );
}

sub render_edit_button
{
	my( $self, $stage ) = @_;

	my $session = $self->{session};

	my $button = $self->render_action_button({
		screen => $session->plugin( "Screen::".$self->edit_screen,
			processor => $self->{processor},
		),
		screen_id => "Screen::".$self->edit_screen,
		hidden => {
			dataset => $self->{processor}->{dataset}->id,
			dataobj => $self->{processor}->{dataobj}->id,
			stage => $stage->get_name,
		},
		idsuffix => "stage_" . $stage->get_name,
	});

	return $session->template_phrase( "view:EPrints/Plugin/Screen/Workflow/Details:render_edit_button", { item => {
		button => $button,
	} } );
}

sub render_stage_warnings
{
	my( $self, $stage ) = @_;

	my @problems = $stage->validate( $self->{processor} );
	my $problems_info = [];

	if (scalar @problems )
	{
		foreach my $problem ( @problems )
		{
			push @$problems_info, {
				problem => $problem,
			};
		}
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Workflow/Details:render_stage_warnings", {
		workflow => $self->workflow,
		item => {
			has_problems => !!(scalar @problems),
			problems => $problems_info,
			stage => $stage,
		},
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

