=head1 NAME

EPrints::Plugin::Screen::EPrint::Document::MoveDown

=cut

package EPrints::Plugin::Screen::EPrint::Document::MoveDown;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::Document' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_down.svg";

	$self->{appears} = [
		{
			place => "document_item_actions",
			position => 1010,
		},
	];
	
	$self->{actions} = [qw//];

	$self->{ajax} = "automatic";

	return $self;
}

sub from
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	my $doc = $self->{processor}->{document};
	my @docs = $eprint->get_all_documents;

	if( $doc )
	{
		my $i;
		for($i = 0; $i < @docs; ++$i)
		{
			last if $doc->id == $docs[$i]->id;
		}
		if( $i == $#docs )
		{
			my $t = $docs[0]->value( "placement" );
			for($i = 0; $i < $#docs; ++$i)
			{
				$docs[$i]->set_value( "placement",
					$docs[$i+1]->value( "placement" )
				);
			}
			$docs[$#docs]->set_value( "placement", $t );
			$_->commit for @docs;
			return;
		}
		my( $left, $right ) = @docs[($i+1)%@docs, $i];
		my $t = $left->value( "placement" );
		$left->set_value( "placement", $right->value( "placement" ) );
		$right->set_value( "placement", $t );
		$left->commit;
		$right->commit;
	}

	$self->{processor}->{redirect} = $self->{processor}->{return_to};
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

