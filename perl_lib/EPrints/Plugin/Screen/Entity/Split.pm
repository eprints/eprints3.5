=head1 NAME

EPrints::Plugin::Screen::Entity::Split

=cut

package EPrints::Plugin::Screen::Entity::Split;

use EPrints::Plugin::Screen::Entity;

@ISA = ( 'EPrints::Plugin::Screen::Entity' );

use strict;
use Encode;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ split /];

	$self->{icon} = "action_edit.svg";

	$self->{appears} = [
		{
			place => "entity_actions",
			position => 270,
		},
	];

	$self->{staff} = 0;

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 if !$self->has_workflow();

	return $self->allow( $self->{processor}->{dataset}->id . "/edit" );
}


sub action_split
{
	my( $self ) = @_;

	my $ds = $self->{repository}->dataset( 'eprint' );

	my $entity_id_value = $self->{session}->param( "entity_id_value" );
	my $entity_id_type = $self->{session}->param( "entity_id_type" );

	my $eprints; 
	my @entity_names;
	my @params = $self->{session}->{query}->multi_param;
	foreach my $p ( @params )
	{
		if ( $p =~ s/^eprint:// )
		{
			my $eprint = $ds->dataobj( $p );
			push @$eprints, $eprint;
			my $contributions = $eprint->get_value( 'contributions' );
			my $changed = 0;
			for ( my $c = 0; $c < scalar @$contributions; $c++ )
			{
				if ( $contributions->[$c]->{contributor}->{datasetid} eq $self->{processor}->{dataset}->id && $contributions->[$c]->{contributor}->{entityid} eq $self->{processor}->{entity}->id && !  grep /$contributions->[$c]->{contributor}->{name}/, @entity_names )
				{
					push @entity_names, $contributions->[$c]->{contributor}->{name};
				}						
			}
		}
	}

	my @deserialized_entity_names;
	foreach my $entity_name ( @entity_names )
	{
		if ( my $f = $self->{session}->config( 'entities', $self->{processor}->{dataset}->id, 'human_deserialise_name' ) )
		{
			push @deserialized_entity_names, { name => &$f( $entity_name ) };
		}
		else
		{
			push @deserialized_entity_names, { name => $entity_name };
		}
	}
 
	my $new_entity_data = { names => \@deserialized_entity_names, ids => [ { id => $entity_id_value, id_type => $entity_id_type } ] };
	my $entity_dataset = $self->{session}->dataset( $self->{processor}->{dataset}->id );
	my $new_entity = $entity_dataset->create_dataobj( $new_entity_data );
	$new_entity->commit( 1 );

	my $total_changed = 0;
	foreach my $eprint ( @$eprints )
	{
		my $contributions = $eprint->get_value( 'contributions' );
		my $changed = 0;
		for ( my $c = 0; $c < scalar @$contributions; $c++ )
		{
			if ( $contributions->[$c]->{contributor}->{datasetid} eq $self->{processor}->{dataset}->id && $contributions->[$c]->{contributor}->{entityid} eq $self->{processor}->{entity}->id )
			{
				$contributions->[$c]->{contributor}->{entityid} = $new_entity->id;
				$changed = 1;
			}
		}
		if ( $changed )
		{
			$eprint->set_value( 'contributions', $contributions );
			$eprint->commit(1);
			$total_changed++;
		}
	}
	my $to_href_text = $self->html_phrase( "split_entity_href_text", to_type => $self->{session}->html_phrase( "eprint_fieldopt_contributions_contributor_datasetid_" . $self->{processor}->{dataset}->id ), to_id => $self->{session}->make_text( $new_entity->id ) );
	my $to_href = $self->{session}->make_element( 'a', href => $new_entity->get_control_url );
	$to_href->appendChild( $to_href_text );
	$self->{processor}->add_message( "message", $self->html_phrase( "split_entity", to_href => $to_href, count => $self->{session}->make_text( $total_changed ) ) );
}

sub allow_split
{
	my( $self ) = @_;

	return $self->can_be_viewed;
}

sub render
{
	my( $self ) = @_;

	my $form = $self->render_form;

	my $ds = $self->repository->dataset( "eprint" );

	my $db = $self->repository->get_database;
	my $sth = $db->prepare_select(
	  	sprintf("SELECT %s, %s FROM %s WHERE %s = %s AND %s = %s ORDER BY %s",
			$db->quote_identifier( "eprintid" ),
			$db->quote_identifier( "contributions_contributor_name" ),
			$db->quote_identifier( "eprint_contributions_contributor" ),
			$db->quote_identifier( "contributions_contributor_datasetid" ),
			$db->quote_value( $self->{processor}->{dataset}->id ),
			$db->quote_identifier( "contributions_contributor_entityid" ),
			$db->quote_value( $self->{processor}->{entity}->id ),
			$db->quote_identifier( "contributions_contributor_name" ),			
		)
	);
	$sth->execute;	

	my $hr_name = Encode::encode( "UTF-8", $self->{processor}->{entity}->human_serialise_name( $self->{processor}->{entity}->get_value( 'name' ) ) );
	my @eprint_cbtr_order = ( $hr_name );
	my %eprint_cbtr_names = ( $hr_name => [] );
	while (my $row = $sth->fetchrow_arrayref) 
	{
		push @eprint_cbtr_order, $row->[1] unless defined $eprint_cbtr_names{$row->[1]};
		push @{$eprint_cbtr_names{$row->[1]}}, $row->[0];
	}

	my $contrib_frag = $self->{session}->make_doc_fragment; 
	foreach my $eprint_cbtr_name ( @eprint_cbtr_order )
	{
		my $heading = $self->{session}->make_element( 'h2', class => "ep_entity_name" );
		$heading->appendChild( $self->{session}->make_text( $eprint_cbtr_name ) );
		my $eprints_div = $self->{session}->make_element( 'div', class => "ep_entity_name_contribs" );
		$contrib_frag->appendChild( $heading );
		my $n = 0;
		foreach my $eprintid ( @{$eprint_cbtr_names{$eprint_cbtr_name}} )
		{
			$n++;
			my $eprint = $ds->dataobj( $eprintid );
			$eprints_div->appendChild( $eprint->render_citation( 'result_checkbox', n => [ $n, 'INTEGER' ] ) );
		}
		$contrib_frag->appendChild( $eprints_div );
	}

	my $id_div = $self->{session}->make_element( 'div', class => "ep_entity_ids" );
	my $id_label = $self->{session}->make_element( 'label', id => "choose_entity_id" );
	$id_label->appendChild( $self->{session}->html_phrase( 'lib/submissionform:choose_entity_id' ) );
	$id_label->appendChild( $self->{session}->make_text( ': ' ) );
	$id_div->appendChild( $id_label );
	my $id_type_select = $self->{session}->make_element( 'select', id => "ep_entity_id_type_select", name => 'entity_id_type', 'aria-labelledby' => 'choose_entity_id' );
	foreach my $option ( @{$self->{session}->{types}->{$self->{processor}->{dataset}->id."_id_type"}} )
	{
		my $option_label = $self->{session}->make_text( $self->{session}->phrase( $self->{processor}->{dataset}->id . "_id_type_typename_" . $option ) ); 
		my $id_type_option;
		$id_type_option = $self->{session}->make_element( 'option', value => $option );

		$id_type_option->appendChild(  $self->{session}->make_text( $option_label ) );
		$id_type_select->appendChild( $id_type_option );
	}
	$id_div->appendChild( $id_type_select );
	my $id_value_input = $self->{session}->make_element( 'input', id => "ep_entity_id_value_input", name => 'entity_id_value', 'aria-labelledby' => 'choose_entity_id' );
	$id_div->appendChild( $id_value_input );

	$form->appendChild( $contrib_frag );
	$form->appendChild( $id_div );
	$form->appendChild( $self->render_buttons( "bottom" ) );

	return $form;
}


sub render_buttons
{
	my( $self, $position ) = @_;

	my $class = "ep_form_button_bar";

	if( defined( $position ))
	{
		$class .= " ep_form_button_bar_$position";
	}

	my %buttons = ( _order=>[], _class=> $class );

	push @{$buttons{_order}}, "split";
	$buttons{split} = 
		$self->{session}->phrase( "lib/submissionform:action_split" );

	return $self->{session}->render_action_buttons( %buttons );
}

1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

