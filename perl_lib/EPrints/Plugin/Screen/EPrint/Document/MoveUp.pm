=head1 NAME

EPrints::Plugin::Screen::EPrint::Document::MoveUp

=cut

package EPrints::Plugin::Screen::EPrint::Document::MoveUp;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint::Document' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{icon} = "action_up.svg";

	$self->{appears} = [
		{
			place => "document_item_actions",
			position => 1000,
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
		if( $i == 0 )
		{
			my $t = $docs[$#docs]->value( "placement" );
			for($i = $#docs; $i > 0; --$i)
			{
				$docs[$i]->set_value( "placement",
					$docs[$i-1]->value( "placement" ) );
			}
			$docs[0]->set_value( "placement", $t );
			$_->commit for @docs;
			return;
		}
		my( $left, $right ) = @docs[($i-1)%@docs, $i];
		my $t = $left->value( "placement" );
		$left->set_value( "placement", $right->value( "placement" ) );
		$right->set_value( "placement", $t );
		$left->commit;
		$right->commit;
		push @{$self->{processor}->{docids}},
			$left->id,
			$right->id;
	}

	$self->{processor}->{redirect} = $self->{processor}->{return_to};
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
