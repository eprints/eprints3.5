=head1 NAME

EPrints::Plugin::Screen::Entity

=cut


package EPrints::Plugin::Screen::Entity;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $session = $self->{session};

	my $datasetid = $session->param( "dataset" );
	my $entityid = $session->param( "dataobj" );

	my $dataset = $self->{processor}->{dataset};
	$dataset = $session->dataset( $datasetid ) if !defined $dataset;
	my $entity_dss = $session->config( 'entities', 'datasets' );
	if( !defined $dataset || ! grep /^$datasetid$/, @$entity_dss )
	{
		$processor->{screenid} = "Error";
		$processor->add_message( "error", $session->html_phrase(
			"cgi/users/edit_entity:cant_find_it",
			dataset=>$self->{session}->make_text( $datasetid ),
			dataobj=>$self->{session}->make_text( $entityid ) ) );
		return;
	}
	$self->{processor}->{dataset} = $dataset;

	my $entity = $processor->{entity};
	$entity = $dataset->dataobj( $entityid ) if !defined $entity;
	if( !defined $entity )
	{
		$processor->{screenid} = "Error";
		$processor->add_message( "error", $session->html_phrase(
			"cgi/users/edit_entity:cant_find_it",
			dataset=>$self->{session}->make_text( $datasetid ),
			dataobj=>$self->{session}->make_text( $entityid ) ) );
		return;
	}
	$processor->{entity} = $entity;

	unless (defined $self->{processor}->{required_fields_only}) {
		$self->{processor}->{required_fields_only} = $self->{session}->param( "required_only" );
	}

	$self->SUPER::properties_from;
}

sub allow
{
	my( $self, $priv ) = @_;

	# Allow Entity::View icon to be displayed under Listing pages actions for entity datasets.
	if ( $self->{processor}->{screenid} eq "Listing" && $self->{processor}->{dataset} )
	{
		my $entity_dss = $self->{session}->config( 'entities', 'datasets' );
		my $datasetid = $self->{processor}->{dataset}->id;
		return 1 if grep /^$datasetid$/, @$entity_dss;
	}

	return 0 unless defined $self->{processor}->{entity};

	return 1 if( $self->{session}->allow_anybody( $priv ) );
	return 0 if( !defined $self->{session}->current_user );
	return $self->{session}->current_user->allow( $priv, $self->{processor}->{entity} );
}

sub has_workflow
{
	my( $self ) = @_;

	my $xml = $self->{session}->get_workflow_config( $self->{processor}->{dataset}->id, "default" );

	return defined $xml;
}

sub render_tab_title
{
	my( $self ) = @_;

	return $self->html_phrase( "title" );
}

sub render_title
{
	my( $self ) = @_;

	my $priv = $self->allow( $self->{processor}->{dataset}->id."/view" );
	my $owner  = $priv & 4;
	my $editor = $priv & 8;

	my $f = $self->{session}->make_doc_fragment;
	$f->appendChild( $self->html_phrase( "title" ) );
	$f->appendChild( $self->{session}->make_text( ": " ) );

	my $title = $self->{processor}->{entity}->render_citation( "screen" );
	if( $owner && $editor )
	{
		$f->appendChild( $title );
	}
	else
	{
		my $a = $self->{session}->render_link( "?screen=Entity::View&dataset=".$self->{processor}->{dataset}->id."&dataobj=".$self->{processor}->{entity}->id );
		$a->appendChild( $title );
		$f->appendChild( $a );
	}
	return $f;
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	return $self->SUPER::redirect_to_me_url."&dataset=".$self->{processor}->{dataset}->id."&dataobj=".$self->{processor}->{entity}->id;
}

sub register_furniture
{
	my( $self ) = @_;

	$self->SUPER::register_furniture;

	my $entity = $self->{processor}->{entity};
	my $user = $self->{session}->current_user;

	return $self->{session}->make_doc_fragment;
}

sub workflow
{
	my( $self ) = @_;

	if( !defined $self->{processor}->{workflow} )
	{
		# look up and use the custom callback if its defined
		my $fn = $self->{session}->get_conf( "STAFF_ONLY_LOCAL_callback" );
		my $soa = ( defined $fn && ref $fn eq "CODE" ) ? &{$fn}( $self->{processor}->{entity}, $self->{session}->current_user, "write" ) : 0;

		my $staff = $self->allow( "entity/edit:editor" );
		my %opts = (
			item => $self->{processor}->{entity},
			session => $self->{session},
			processor => $self->{processor},
			STAFF_ONLY => [$staff ? "TRUE" : "FALSE", "BOOLEAN"],
			STAFF_ONLY_LOCAL => [$soa ? "TRUE" : "FALSE", "BOOLEAN"],
		);
		
		my $user = $self->{session}->current_user;
		if( $user )
		{
			foreach my $role ( $user->get_roles )
			{
				$role =~ s|/|__|g; # replace / with __
				$opts{ "ROLE_" . $role } = [ "TRUE", "BOOLEAN" ];
			}
			$opts{ "ROLES" } = [ join("|", $user->get_roles), "STRING" ];
		}

 		$self->{processor}->{workflow} = EPrints::Workflow->new(
				$self->{session},
				$self->workflow_id,
				%opts
		);
	}

	return $self->{processor}->{workflow};
}

sub workflow_id
{
	return "default";
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

	my $entity = $self->{processor}->{entity};
	my $session = $self->{session};

	my $workflow = $self->workflow;
	my $table = $session->make_element( "div", class=>"ep_blister_bar" );
	my $tr = $session->make_element( "div" );
	$table->appendChild( $tr );
	my $first = 1;
	my @stages = $workflow->get_stage_ids;
	foreach my $stage_id ( @stages )
	{
		if( !$first )  
		{ 
			my $td = $session->make_element( "div", class=>"ep_blister_join" );
			$tr->appendChild( $td );
		}
		
		my $td;
		$td = $session->make_element( "div" );
		my $class = "ep_blister_node";
		if( $stage_id eq $sel_stage_id ) 
		{ 
			$class="ep_blister_node_selected"; 
		}
		my $phrase = $session->phrase( "metapage_title_".$stage_id );
		my $button = $session->render_button(
			name  => "_action_jump_$stage_id", 
			value => $phrase,
			class => $class );

		$td->appendChild( $button );
		$tr->appendChild( $td );
		$first = 0;
	}

	return $table;
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		$self->SUPER::hidden_bits,
		dataset => $self->{processor}->{dataset}->id,
		dataobj => $self->{processor}->{entity}->id,
	);
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

