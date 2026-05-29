=head1 NAME

EPrints::Plugin::Screen::MetaField::Destroy

=cut

package EPrints::Plugin::Screen::MetaField::Destroy;

use EPrints::Plugin::Screen::Workflow::Destroy;
@ISA = qw( EPrints::Plugin::Screen::Workflow::Destroy );

sub edit_screen { "MetaField::Edit" }
sub view_screen { "MetaField::View" }
sub listing_screen { "MetaField::Listing" }
sub can_be_viewed
{
	my( $self ) = @_;

	return $self->{processor}->{dataobj}->isa( "EPrints::DataObj::MetaField" ) && $self->allow( "config/edit/perl" );
}

sub action_remove
{
	my( $self ) = @_;

	return if !$self->SUPER::action_remove;

	$self->{processor}->{notes}->{dataset} = $self->{session}->dataset( $self->{processor}->{dataobj}->value( "mfdatasetid" ) );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
