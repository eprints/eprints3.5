=head1 NAME

EPrints::Plugin::Screen::Entity::UpdateNames

=cut

package EPrints::Plugin::Screen::Entity::UpdateNames;

use EPrints::Plugin::Screen::Entity;

@ISA = ( 'EPrints::Plugin::Screen::Entity' );

use strict;
use Encode;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ update_names /];

	$self->{icon} = "action_edit.png";

	$self->{appears} = [
		{
			place => "entity_actions",
			position => 250,
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


sub action_update_names
{
	my( $self ) = @_;

	my $ds = $self->{repository}->dataset( 'eprint' );

	my $entity_name = $self->{session}->param( "entity_name" );
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
				if ( $contributions->[$c]->{contributor}->{datasetid} eq $self->{processor}->{dataset}->id && $contributions->[$c]->{contributor}->{entityid} eq $self->{processor}->{entity}->id && $contributions->[$c]->{contributor}->{name} ne $entity_name )
				{
					$contributions->[$c]->{contributor}->{name} = $entity_name;
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
	$self->{processor}->add_message( "message", $self->html_phrase( "updated_names", to => $self->{session}->make_text( $entity_name ), count => $self->{session}->make_text( $total_changed ) ) );
}

sub allow_update_names
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
	my $name_div = $self->{session}->make_element( 'div', class => "ep_entity_names" );
	my $name_label =  $self->{session}->make_element( 'label', for => "ep_entity_name_select" );
	$name_label->appendChild( $self->{session}->html_phrase( 'lib/submissionform:select_entity_name' ) );
	$name_label->appendChild( $self->{session}->make_text( ': ' ) );
	
	$name_div->appendChild( $name_label );
	my $name_select = $self->{session}->make_element( 'select', id => "ep_entity_name_select", name => 'entity_name' );
	foreach my $option ( @{$self->{processor}->{entity}->get_value( 'names' )} ) 
	{
	
		my $hr_option = $self->{processor}->{entity}->human_serialise_name( $option->{name} );
		my $name_option;
		if ( $hr_option eq $hr_name )
		{
			$name_option = $self->{session}->make_element( 'option', value => $hr_option, selected => "selected" );
		}
		$name_option = $self->{session}->make_element( 'option', value => $hr_option );

		$name_option->appendChild(  $self->{session}->make_text( $hr_option ) );
		$name_select->appendChild( $name_option );
	}
	$name_div->appendChild( $name_select );	

	$form->appendChild( $contrib_frag );
	$form->appendChild( $name_div );
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

	push @{$buttons{_order}}, "update_names";
	$buttons{update_names} = 
		$self->{session}->phrase( "lib/submissionform:action_update_names" );

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

