=head1 NAME

EPrints::Plugin::Screen::Entity::Actions

=cut

package EPrints::Plugin::Screen::Entity::Actions;

our @ISA = ( 'EPrints::Plugin::Screen::Entity' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "entity_view_tabs",
			position => 300,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return 0 unless scalar $self->action_list( "entity_actions" );

	return $self->who_filter;
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $entityid_fieldname = $self->{processor}->{entity}->get_dataset->get_key_field->{name};

	my $frag = $session->make_doc_fragment;
	my $table = $session->make_element( "table" );
	$frag->appendChild( $table );
	my( $contents, $tr, $th, $td );

	$contents = $self->render_action_list( "entity_actions", { dataset => $self->{processor}->{dataset}->id , dataobj => $self->{processor}->{entity}->id } );

	if( $contents->hasChildNodes )
	{
		$tr = $table->appendChild( $session->make_element( "tr" ) );
		$td = $tr->appendChild( $session->make_element( "td" ) );
		$td->appendChild( $contents );
	}

	return $frag;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
