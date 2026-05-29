=head1 NAME

EPrints::Plugin::Screen::Workflow::Export

=cut

package EPrints::Plugin::Screen::Workflow::Export;

our @ISA = ( 'EPrints::Plugin::Screen::Workflow' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "dataobj_view_tabs",
			position => 500,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	my @plugins = $self->{session}->get_plugins(
		type=>"Export",
		can_accept=>"dataobj/".$self->{processor}->{dataset}->id,
		is_advertised=>1,
		is_visible=>"staff" );

	return $self->allow( $self->dataset->id."/export" ) && scalar @plugins;
}

sub render
{
	my( $self ) = @_;

	my ($data,$title) = $self->dataobj->render_export_links( 1 );

	my $div = $self->{session}->make_element( "div",class=>"ep_block" );
	$div->appendChild( $data );
	return $div;
}	


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
