=head1 NAME

EPrints::Plugin::Screen::Staff::HistorySearch

=cut


package EPrints::Plugin::Screen::Staff::HistorySearch;

@ISA = ( 'EPrints::Plugin::Screen::AbstractSearch' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{
			place => "admin_actions_editorial",
			position => 700,
		},
	];

	$self->{search_result_style} = 'paginate';

	return $self;
}

sub search_dataset
{
	my( $self ) = @_;

	return $self->{session}->get_repository->get_dataset( "history" );
}

sub search_filters
{
	my( $self ) = @_;

	return;
}

sub render_links
{
	my( $self ) = @_;

	my $f = $self->{session}->make_doc_fragment;
	if( $self->{processor}->{search_subscreen} eq "results" )
	{
		my $style = $self->{session}->make_element( "style", type=>"text/css" );
		$style->appendChild( $self->{session}->make_text( ".ep_tm_main { width: 90%; }" ) );
		$f->appendChild( $style );
	}

	$f->appendChild( $self->SUPER::render_links );
	return $f;
}

sub allow_export { return 1; }

sub allow_export_redir { return 1; }

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "staff/history_search" );
}

sub from
{
	my( $self ) = @_;

	my $sconf = {
		search_fields => [
			{ meta_fields => [ "userid.username" ] },
			{ meta_fields => [ "action" ] },
			{ meta_fields => [ "timestamp" ] },
			{ meta_fields => [ "objectid" ] },
		],
		order_methods => {
			userid => "userid",
			timestamp => "timestamp",
			timestampdesc => "-timestamp",
			objectid => "objectid",
		},
		default_order => "timestampdesc",
	};

			
	$self->{processor}->{sconf} = $sconf;

	$self->SUPER::from;
}

sub _vis_level
{
	my( $self ) = @_;

	return "staff";
}

sub get_controls_before
{
	my( $self ) = @_;

	return $self->get_basic_controls_before;	
}

sub render_result_row
{
	my( $self, $session, $result, $searchexp, $n ) = @_;

	return $result->render_citation_link_staff(
			$self->{processor}->{sconf}->{citation},  #undef unless specified
			n => [$n,"INTEGER"] );
}




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

