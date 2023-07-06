=head1 NAME

EPrints::Plugin::Screen::Review

=cut


package EPrints::Plugin::Screen::Review;

use EPrints::Plugin::Screen::Listing;

@ISA = ( 'EPrints::Plugin::Screen::Listing' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 400,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "editorial_review" );
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{session};

	$processor->{dataset} = $repo->dataset( "buffer" );
	$processor->{columns_key} = "screen.review.columns";

	$self->SUPER::properties_from;
}

sub render_title
{
	my( $self ) = @_;

	return $self->EPrints::Plugin::Screen::render_title();
}

sub get_filters
{
	my( $self ) = @_;

	return(
		{ meta_fields => [qw( eprint_status )], value => "buffer", },
	);
}

sub perform_search
{
	my( $self ) = @_;

	my $repo = $self->{session};

	my $list = $repo->current_user->editable_eprints_list( filters => [
		$self->get_filters,
	]);
	my $filter_list = $self->{processor}->{search}->perform_search;

	return $list->intersect( $filter_list );
}

sub render_top_bar
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;

	my $has_editperms = $user->is_set( "editperms" );
	my $editperms_description;

	if( $user->is_set( "editperms" ) )
	{
		$editperms_description = $session->html_phrase( 
			"cgi/users/buffer:buffer_scope",
			scope=>$user->render_value( "editperms" ) );
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Review:render_top_bar", { item => {
		has_editperms => $has_editperms,
		editperms_description => $editperms_description,
		intro_title => $session->html_phrase( "Plugin/Screen/Review:help_title" ),
		intro_content => $session->html_phrase( "Plugin/Screen/Review:help" ),
	} } );
}

sub render_dataobj_actions
{
	my( $self, $dataobj ) = @_;

	my $datasetid = $self->{processor}->{dataset}->id;

	local $self->{processor}->{eprint} = $dataobj; # legacy

	return $self->render_action_list_icons( "eprint_review_actions", {
			eprintid => $dataobj->id,
		} );
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

