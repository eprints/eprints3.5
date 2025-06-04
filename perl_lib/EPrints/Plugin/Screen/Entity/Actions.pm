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

