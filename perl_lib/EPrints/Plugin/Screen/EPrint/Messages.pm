=head1 NAME

EPrints::Plugin::Screen::EPrint::Messages

=cut

package EPrints::Plugin::Screen::EPrint::Messages;

our @ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "eprint_view_tabs",
			position => 550,
		}
	];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	if( $self->get_messages->count == 0 )
	{
		return 0;
	}

	return $self->allow( "eprint/messages" );
}


sub get_messages
{
	my( $self ) = @_;

	my $cache_id = "messages_".$self->{processor}->{eprint}->get_id;

	if( !defined $self->{processor}->{$cache_id} )
	{
		my $ds = $self->{session}->get_repository->get_dataset( "history" );
		my $searchexp = EPrints::Search->new(
			session=>$self->{session},
			dataset=>$ds,
			custom_order=>"-timestamp/-historyid" );
		
		$searchexp->add_field(
			$ds->get_field( "objectid" ),
			$self->{processor}->{eprint}->get_id );
		$searchexp->add_field(
			$ds->get_field( "datasetid" ),
			'eprint' );
		$searchexp->add_field(
			$ds->get_field( "action" ),
			'mail_owner note',
			'IN',
			'ANY' );
		
		$self->{processor}->{$cache_id} = $searchexp->perform_search;
	}
	return $self->{processor}->{$cache_id};
}

sub render
{
	my( $self ) = @_;

	my $page = $self->{session}->make_doc_fragment;

	my $results = $self->get_messages;

	if( $results->count )
	{
		$results->map( sub {
			my( $session, $dataset, $item ) = @_;
		
			$page->appendChild( $item->render );
		} );
	}
	else
	{
		$page->appendChild( $self->html_phrase( "no_messages" ) );
	}

	return $page;
}	


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
