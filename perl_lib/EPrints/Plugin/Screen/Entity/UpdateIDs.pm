=head1 NAME

EPrints::Plugin::Screen::Entity::UpdateIDs

=cut

package EPrints::Plugin::Screen::Entity::UpdateIDs;

use EPrints::Plugin::Screen::Entity;

@ISA = ( 'EPrints::Plugin::Screen::Entity' );

use MIME::Base64 qw( decode_base64 encode_base64 );
use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ update_ids /];

	$self->{icon} = "action_edit.png";

	$self->{appears} = [
		{
			place => "entity_actions",
			position => 260,
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


sub action_update_ids
{
	my( $self ) = @_;

	my $ds = $self->{repository}->dataset( 'eprint' );

	my @entity_id_type_value_encode = split( ':', $self->{session}->param( "entity_id" ) );
	my $entity_id_type = decode_base64( $entity_id_type_value_encode[0] );
	my $entity_id_value = decode_base64( $entity_id_type_value_encode[1] );
	my @params = $self->{session}->{query}->multi_param;
	my $total_changed = 0;
	foreach my $p ( @params )
	{
		if ( $p =~ s/^eprint:// )
		{
			my $eprint = $ds->dataobj( $p );
			my $contributions = $eprint->get_value( 'contributions' );
			my $changed = 0;
			for ( my $c = 0; $c < scalar @$contributions; $c++ )
			{
				if ( $contributions->[$c]->{contributor}->{datasetid} eq $self->{processor}->{dataset}->id && $contributions->[$c]->{contributor}->{entityid} eq $self->{processor}->{entity}->id && ( $contributions->[$c]->{contributor}->{id_value} ne $entity_id_value || $contributions->[$c]->{contributor}->{id_type} ne $entity_id_type ) )
				{
					$contributions->[$c]->{contributor}->{id_value} = $entity_id_value;
					$contributions->[$c]->{contributor}->{id_type} = $entity_id_type;
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
	}
	$self->{processor}->add_message( "message", $self->html_phrase( "updated_ids", to_value => $self->{session}->make_text( $entity_id_value ), to_type => $self->{session}->make_text( $entity_id_type ), count => $self->{session}->make_text( $total_changed ) ) );
}

sub allow_update_ids
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
      	sprintf("SELECT %s, %s, %s FROM %s WHERE %s = %s AND %s = %s ORDER BY %s, %s",
			$db->quote_identifier( "eprintid" ),
		    $db->quote_identifier( "contributions_contributor_id_type" ),
			$db->quote_identifier( "contributions_contributor_id_value" ),
			$db->quote_identifier( "eprint_contributions_contributor" ),
			$db->quote_identifier( "contributions_contributor_datasetid" ),
			$db->quote_value( $self->{processor}->{dataset}->id ),
			$db->quote_identifier( "contributions_contributor_entityid" ),
			$db->quote_value( $self->{processor}->{entity}->id ),
			$db->quote_identifier( "contributions_contributor_id_type" ),			
			$db->quote_identifier( "contributions_contributor_id_value" ),
		)
	);

	$sth->execute;	
	
	my $primary_id = encode_base64( $self->{processor}->{entity}->get_value( 'id_type' ) ). ":" . encode_base64( $self->{processor}->{entity}->get_value( 'id_value' ) );
	my @eprint_cbtr_order = ( $primary_id );
 	my %eprint_cbtr_ids = ( $primary_id => [] );
	while (my $row = $sth->fetchrow_arrayref) 
	{
		my $option_encode = encode_base64( $row->[1] ) . ":" . encode_base64( $row->[2] );
		push @eprint_cbtr_order, $option_encode unless defined $eprint_cbtr_ids{$option_encode};
		push @{$eprint_cbtr_ids{$option_encode}}, $row->[0];
	}

	my $contrib_frag = $self->{session}->make_doc_fragment; 
	foreach my $eprint_cbtr_id ( @eprint_cbtr_order )
	{
		my $heading = $self->{session}->make_element( 'h2', class => "ep_entity_id" );
		my @id_type_value = split( ':',  $eprint_cbtr_id );

		$heading->appendChild( $self->{session}->html_phrase( $self->{processor}->{dataset}->id . "_id_type_typename_" . decode_base64( $id_type_value[0] ) ) );
		$heading->appendChild( $self->{session}->make_text( ": " . decode_base64( $id_type_value[1] ) ) );
		my $eprints_div = $self->{session}->make_element( 'div', class => "ep_entity_id_contribs" );
		$contrib_frag->appendChild( $heading );
		my $n = 0;
		foreach my $eprintid ( @{$eprint_cbtr_ids{$eprint_cbtr_id}} )
		{
			$n++;
			my $eprint = $ds->dataobj( $eprintid );
			$eprints_div->appendChild( $eprint->render_citation( 'result_checkbox', n => [ $n, 'INTEGER' ] ) );
		}
		$contrib_frag->appendChild( $eprints_div );
	}
	my $id_div = $self->{session}->make_element( 'div', class => "ep_entity_ids" );
	my $id_label =  $self->{session}->make_element( 'label', for => "ep_entity_id_select" );
	$id_label->appendChild( $self->{session}->html_phrase( 'lib/submissionform:select_entity_id' ) );
	$id_label->appendChild( $self->{session}->make_text( ': ' ) );
	
	$id_div->appendChild( $id_label );
	my $id_select = $self->{session}->make_element( 'select', id => "ep_entity_id_select", name => 'entity_id' );
	foreach my $option ( @{$self->{processor}->{entity}->get_value( 'ids' )} ) 
	{
		my $option_encode = encode_base64( $option->{id_type} ) . ": " . encode_base64( $option->{id} );
		my $option_label = $self->{session}->make_text( $self->{session}->phrase( $self->{processor}->{dataset}->id . "_id_type_typename_" . $option->{id_type} ) . ": " . $option->{id} );
		my $id_option;
		if ( $option_encode eq $primary_id )
		{
			$id_option = $self->{session}->make_element( 'option', value => $option_encode, selected => "selected" );
		}
		$id_option = $self->{session}->make_element( 'option', value => $option_encode );

		$id_option->appendChild(  $self->{session}->make_text( $option_label ) );
		$id_select->appendChild( $id_option );
	}
	$id_div->appendChild( $id_select );	

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

	push @{$buttons{_order}}, "update_ids";
	$buttons{update_ids} = 
		$self->{session}->phrase( "lib/submissionform:action_update_ids" );

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

