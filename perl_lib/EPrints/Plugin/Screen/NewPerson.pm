=head1 NAME

EPrints::Plugin::Screen::NewPerson

=cut


package EPrints::Plugin::Screen::NewPerson;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ create cancel /];

	$self->{appears} = [
		{ 
			place => "admin_actions_system", 	
			position => 1010, 
		},
	];

	return $self;
}

sub can_be_viewed
{
	my ( $self ) = @_;

	return $self->allow( "create_person" );
}

sub allow_cancel
{
	my ( $self ) = @_;

	return 1;
}

sub action_cancel
{
	my( $self ) = @_;

	$self->{processor}->{screenid} = "Admin";
}

sub allow_create
{
	my ( $self ) = @_;

	return $self->allow( "create_person" );
}

sub action_create
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $ds = $session->dataset( "person" );

	my $candidate_id = $session->param( "id_value" );
	my $candidate_id_type = $session->param( "id_type" );

	unless( EPrints::Utils::is_set( $candidate_id ) )
	{
		$self->{processor}->add_message( 
			"warning",
			$self->html_phrase( "no_id_value" ) );
		return;
	}

    unless( EPrints::Utils::is_set( $candidate_id_type ) )
    {
        $self->{processor}->add_message(
            "warning",
            $self->html_phrase( "no_id_type" ) );
        return;
    }

	if( my $person = EPrints::DataObj::Entity::entity_with_id( $session, $ds, $candidate_id, $candidate_id_type ) )
	{
		$self->{processor}->add_message( 
			"error",
			$self->html_phrase( "person_exists",
				id_value => $session->make_text( $candidate_id ),
				id_type => $session->make_text( $candidate_id_type ),
			) );
		return;
	}

	# Attempt to create a new account

	$self->{processor}->{person} = $ds->create_object( $self->{session}, { 
		ids => [ 
			{ 
				id => $candidate_id, 
				id_type => $candidate_id_type,
			}
		],
		id_value => $candidate_id,
                id_type => $candidate_id_type,
	} );

	if( !defined $self->{processor}->{person} )
	{
		my $db_error = session->get_database->error;
		$session->get_repository->log( "Database Error: $db_error" );
		$self->{processor}->add_message( 
			"error",
			$self->html_phrase( "db_error" ) );
		return;
	}

	$self->{processor}->{dataset} = $ds;
	$self->{processor}->{dataobj} = $self->{processor}->{person};
	$self->{processor}->{screenid} = "Workflow::Edit";
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $page = $session->make_element( "div", class=>"ep_block" );

	$page->appendChild( $self->html_phrase( "blurb" ) );

	my %buttons = (
		cancel => $self->phrase( "action:cancel:title" ),
		create => $self->phrase( "action:create:title" ),
		_order => [ "create", "cancel" ]
	);

	my $form = $session->render_form( "GET" );
	$form->appendChild( 
		$session->render_hidden_field ( "screen", "NewPerson" ) );		
	my $ds = $session->dataset( "person" );
	my $id_value_field = $ds->get_field( "id_value" );
	my $id_type_field = $ds->get_field( "id_type" );
	my $div = $session->make_element( "div", style=>"margin-bottom: 1em" );
	my $idv_label = $session->make_element( "label", for=>"id_value" );
	$idv_label->appendChild( $id_value_field->render_name( $session ) );
	$div->appendChild( $idv_label );
	$div->appendChild( $session->make_text( ": " ) );
	$div->appendChild( 
		$session->make_element( 
			"input",
			"maxlength"=>"255",
			"name"=>"id_value",
			"id"=>"id_value",
			"class"=>"ep_form_text",
			"size"=>"20", ));
    my $idt_label = $session->make_element( "label", for=>"id_type" );
    $idt_label->appendChild( $id_type_field->render_name( $session ) );
	$div->appendChild( $idt_label );
    $div->appendChild( $session->make_text( ": " ) );
    my $select = $session->make_element(
            "select",
            "name"=>"id_type",
            "id"=>"id_type",
            "class"=>"ep_form_select",
    );
	foreach my $idt ( @{$id_type_field->get_values} )
	{
		my $option = $session->make_element( "option", value => $idt );
		$option->appendChild( $session->make_text( $session->phrase( 'person_id_type_typename_' . $idt ) ) );
		$select->appendChild( $option );
	}
	$div->appendChild( $select );
	$form->appendChild( $div );
	$form->appendChild( $session->render_action_buttons( %buttons ) );
	
	$page->appendChild( $form );

	return( $page );
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

