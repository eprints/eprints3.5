=head1 NAME

EPrints::Plugin::Screen::Workflow

=cut


package EPrints::Plugin::Screen::Workflow;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_view.png";

	$self->{appears} = [];

	$self->{actions} = [qw/ /];

	return $self;
}

sub view_screen
{
	my( $self ) = @_;

	return "Workflow::View";
}

sub edit_screen
{
	my( $self ) = @_;

	return "Workflow::Edit";
}

sub listing_screen
{
	my( $self ) = @_;

	return "Listing";
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $session = $self->{session};

	my $datasetid = $session->param( "dataset" );
	my $id = $session->param( "dataobj" );

	my $dataset = $self->{processor}->{dataset};
	$dataset = $session->dataset( $datasetid ) if !defined $dataset;
	if( !defined $dataset )
	{
		$processor->{screenid} = "Error";
		$processor->add_message( "error", $session->html_phrase(
			"lib/history:no_such_item",
			datasetid=>$session->make_text( $datasetid ),
			objectid=>$session->make_text( $id ) ) );
		return;
	}

	$processor->{"dataset"} = $dataset;

	my $dataobj = $self->{processor}->{dataobj};
	$dataobj = $dataset->dataobj( $id ) if !defined $dataobj;
	if( !defined $dataobj )
	{
		$processor->{screenid} = "Error";
		$processor->add_message( "error", $session->html_phrase(
			"lib/history:no_such_item",
			datasetid=>$session->make_text( $datasetid ),
			objectid=>$session->make_text( $id ) ) );
		return;
	}

	$processor->{"dataobj"} = $dataobj;

	$self->{processor}->{return_to} = $session->param( 'return_to' );

	my $plugin = $self->{session}->plugin(
		"Screen::" . $self->edit_screen,
		processor => $self->{processor},
		);
	$self->{processor}->{can_be_edited} = $plugin->can_be_viewed();

	$self->SUPER::properties_from;

	$self->{processor}->{stage} = $self->{session}->param( "stage" );
	$self->{processor}->{component} = $self->{session}->param( "component" );
}

sub allow
{
	my( $self, $priv ) = @_;

	return 0 unless defined $self->{processor}->{dataobj};

	return 1 if( $self->{session}->allow_anybody( $priv ) );
	return 0 if( !defined $self->{session}->current_user );
	return $self->{session}->current_user->allow( $priv, $self->{processor}->{dataobj} );
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( $self->{processor}->{dataset}->id."/edit" );
}

sub allow_action
{
	my( $self, $action ) = @_;

	return $self->can_be_viewed();
}

sub dataset
{
	my( $self ) = @_;

	return $self->{processor}->{dataset};
}

sub dataobj
{
	my( $self ) = @_;

	return $self->{processor}->{dataobj};
}

sub render_tab_title
{
	my( $self ) = @_;

	return $self->html_phrase( "title" );
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	my $url = URI->new($self->SUPER::redirect_to_me_url);
	$url->query_form($self->hidden_bits);

	return $url;
}

sub has_workflow
{
	my( $self ) = @_;

	my $xml = $self->{session}->get_workflow_config( $self->{processor}->{dataset}->base_id, "default" );

	return defined $xml;
}

sub workflow
{
	my( $self, $workflow_id ) = @_;

	my $cache_id = "workflow";
	$workflow_id = "default" if !defined $workflow_id;

	my $user = $self->{session}->current_user;
	my $staff = 0;
	my %opts;
	if( defined $user )
	{
		my $priv = $self->{processor}->{dataset}->id . '/edit';
		# staff mode if user is an admin or has editorial privileges for this
		# object
		$staff =
			($user->allow( $priv, $self->{processor}->{dataobj} ) & 8) ||
			$user->has_role( 'admin' );

		foreach my $role ( $user->get_roles )
		{
			$role =~ s|/|__|g; # replace / with __
			$opts{ "ROLE_" . $role } = [ "TRUE", "BOOLEAN" ];
		}
		$opts{ "ROLES"} = [ join("|", $user->get_roles), "STRING" ];
	}

	if( !defined $self->{processor}->{$cache_id} )
	{
 		$self->{processor}->{$cache_id} = EPrints::Workflow->new( $self->{session}, $workflow_id,
			item => $self->{processor}->{"dataobj"},
			STAFF_ONLY => [$staff ? "TRUE" : "FALSE", "BOOLEAN"],
			processor => $self->{processor},
			%opts,
		);
	}

	return $self->{processor}->{$cache_id};
}

sub current_component
{
	my( $self ) = @_;

	return unless $self->{processor}->{component};
	my $stage = $self->workflow->get_stage( $self->workflow->get_stage_id );
	return unless $stage;
	foreach my $component ($stage->get_components)
	{
		return $component if $component->{prefix} eq $self->{processor}->{component};
	}
	return undef;
}

sub uncache_workflow
{
	my( $self ) = @_;

	delete $self->{session}->{id_counter};
	delete $self->{processor}->{workflow};
	delete $self->{processor}->{workflow_staff};
}

sub render_blister
{
	my( $self, $sel_stage_id ) = @_;

	my $session = $self->{session};

        my %item = (
                stages => [],
        );

	my $workflow = $self->workflow();
	my $first = 1;
	my $selected = 0;
	my @stages = $workflow->get_stage_ids;
	foreach my $stage_id ( @stages )
	{
		my $stage = $workflow->get_stage( $stage_id );

		$selected = $stage_id eq $sel_stage_id ? 1 : 0;
		my $title = $stage->render_title();
		push @{ $item{stages} }, { stage => $session->render_button(
                        name  => "_action_jump_$stage_id",
                        value => $session->xhtml->to_text_dump( $title ),
                        selected => $selected,
			stage => 1 ), first => $first };

		$first = 0;
	}

	return $self->{repository}->template_phrase( "view:EPrints/Plugin/Screen/EPrint:render_blister", { item => \%item } );
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		$self->SUPER::hidden_bits,
		dataset => $self->{processor}->{dataset}->id,
		dataobj => $self->{processor}->{dataobj}->id,
		return_to => scalar($self->repository->param('return_to')),
	);
}

sub _render_action_aux
{
	my( $self, $params, $asicon ) = @_;
	
	my $session = $self->{session};
	
	my $method = "GET";	
	if( defined $params->{action} )
	{
		$method = "POST";
	}

	my $form = $session->render_form( $method, $session->current_url( path => "cgi" ) . "/users/home" );

	my $idsuffix = defined $params->{hidden}->{stage} ? "_stage_" . $params->{hidden}->{stage} : "";

	$form->appendChild( 
		$session->render_hidden_field( 
			"screen", 
			substr( $params->{screen_id}, 8 ), 
			"screen_" . substr( $params->{screen_id}, 8 ) . $idsuffix
		)
	);

	foreach my $id ( keys %{$params->{hidden}} )
	{
		$form->appendChild( 
			$session->render_hidden_field( 
				$id, 
				$params->{hidden}->{$id},
				$id . "_" . substr( $params->{screen_id}, 8 ) . $idsuffix ) );
	}
	my( $action, $title, $icon );
	if( defined $params->{action} )
	{
		$action = $params->{action};
		$title = $params->{screen}->phrase( "action:$action:title" );
		$icon = $params->{screen}->action_icon_url( $action );
	}
	else
	{
		$action = "null";
		$title = $params->{screen}->phrase( "title" );
		$icon = $params->{screen}->icon_url();
	}
	if( defined $icon && $asicon )
	{
		$form->appendChild( 
			$session->make_element(
				"input",
				type=>"image",
				class=>"ep_form_action_icon",
				name=>"_action_$action", 
				src=>$icon,
				title=>$title,
				alt=>$title,
				value=>$title ));
	}
	else
	{
		$form->appendChild( 
			$session->render_button(
				class=>"ep_form_action_button",
				role=>"button",
				name=>"_action_$action", 
				value=>$title ));
	}

	return $form;
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

