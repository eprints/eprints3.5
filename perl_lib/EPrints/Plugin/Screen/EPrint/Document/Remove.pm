=head1 NAME

EPrints::Plugin::Screen::EPrint::Document::Remove

=cut

package EPrints::Plugin::Screen::EPrint::Document::Remove;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::Document' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_remove.svg";

	$self->{appears} = [
		{
			place => "document_item_actions",
			position => 1600,
		},
	];
	
	$self->{actions} = [qw/ remove cancel /];

	$self->{ajax} = "interactive";

	return $self;
}

sub allow_remove { shift->can_be_viewed( @_ ) }
sub allow_cancel { 1 }

sub render
{
	my( $self ) = @_;

	my $doc = $self->{processor}->{document};

	my $frag = $self->{session}->make_doc_fragment;

	my $div = $self->{session}->make_element( "div", class=>"ep_block" );
	$frag->appendChild( $div );

	$div->appendChild( $self->render_document( $doc ) );

	$div = $self->{session}->make_element( "div", class=>"ep_block" );
	$frag->appendChild( $div );

	$div->appendChild( $self->{session}->html_phrase( "Plugin/InputForm/Component/Documents:delete_document_confirm" ) );
	
	my %buttons = (
		cancel => $self->{session}->phrase(
				"lib/submissionform:action_cancel" ),
		remove => $self->{session}->phrase(
				"lib/submissionform:action_remove" ),
		_order => [ "remove", "cancel" ]
	);

	my $form = $self->render_form;
	$form->appendChild( $self->{session}->render_action_buttons( %buttons ) );
	$div->appendChild( $form );

	return( $frag );
}	

sub action_remove
{
	my( $self ) = @_;

	$self->{processor}->{redirect} = $self->{processor}->{return_to}
		if !$self->wishes_to_export;

	if( $self->{processor}->{document} && $self->{processor}->{document}->remove )
	{
		push @{$self->{processor}->{docids}}, $self->{processor}->{document}->id;
		$self->{processor}->add_message( "message", $self->html_phrase( "item_removed" ) );
	}
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

