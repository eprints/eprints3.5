=head1 NAME

EPrints::Plugin::Screen::DataSets

=cut

package EPrints::Plugin::Screen::DataSets;

use EPrints::Plugin::Screen;
@ISA = qw( EPrints::Plugin::Screen );

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 150,
		}
	];

	$self->{actions} = [qw/ /];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "datasets" );
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $xml = $repo->xml;
	my $user = $repo->current_user;
	my $imagesurl = $repo->config( "rel_path" )."/style/images";
	my @datasets = $self->datasets;

	my $item = {
		datasets => []
	};

	if( $repo->get_lang->has_phrase( $self->html_phrase_id( "intro" ), $repo ) )
	{
		$item->{has_intro} = 1;
	}

	foreach my $dataset (@datasets)
	{
		push @{ $item->{datasets} }, {
			id => $dataset->id,
			label => $dataset->render_name( $repo ),
			href => $self->listing( $dataset ),
		}
	}

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/DataSets:render", { item => $item } );
}

sub datasets
{
	my( $self ) = @_;

	return @{$self->{processor}->{datasets}}
		if defined $self->{processor}->{datasets};

	my @datasets;
	
	foreach my $datasetid ($self->{session}->get_dataset_ids)
	{
		my $dataset = $self->{session}->dataset( $datasetid );
		push @datasets, $dataset
			if
				$self->allow( $dataset->id . "/view" ) ||
				$self->allow( $dataset->id . "/view:owner" ) ||
				$self->allow( $dataset->id . "/view:editor" );
	}

	@datasets = sort { $a->base_id cmp $b->base_id || $a->id cmp $b->id } @datasets;

	$self->{processor}->{datasets} = \@datasets;

	return @datasets;
}

sub listing
{
	my( $self, $dataset ) = @_;

	my $url = URI->new( $self->{session}->current_url() );
	$url->query_form(
		screen => "Listing",
		dataset => $dataset->base_id
		);

	return $url;
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

