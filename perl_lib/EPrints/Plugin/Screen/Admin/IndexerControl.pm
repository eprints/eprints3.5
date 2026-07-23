=head1 NAME

EPrints::Plugin::Screen::Admin::IndexerControl

=cut

package EPrints::Plugin::Screen::Admin::IndexerControl;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{actions} = [qw/ restart_indexer retry_tasks clear_tasks /];

	$self->{appears} = [
		{ 
			place => "admin_actions_system",
			action => "restart_indexer",
			position => 1100, 
		},
		{
			place => "admin_actions_system",
			action => "retry_tasks",
			position => 1105,
		},
		{
			place => "admin_actions_system",
			action => "clear_tasks",
			position => 1106,
		},
	];

	$self->{daemon} = EPrints::Index::Daemon->new(
		session => $self->{session}
	);

	return $self;
}

sub get_daemon
{
	my( $self ) = @_;
	return $self->{daemon};
}

sub about_to_render
{
	my( $self ) = @_;
	$self->{processor}->{screenid} = "Admin";
}

sub allow_restart_indexer
{
	my( $self ) = @_;

	return $self->allow( "indexer/restart" );
}

sub action_restart_indexer
{
	my( $self ) = @_;

	my $result = $self->get_daemon->create_suicide_file();

	if( $result == 1 )
	{
		$self->{processor}->add_message( 
			"message", 
			$self->html_phrase( "indexer_stopped" ) 
		);
	}
	else
	{
		$self->{processor}->add_message( 
			"error", 
			$self->html_phrase( "cant_stop_indexer", 
				logpath => $self->{session}->make_text( EPrints::Index::logfile() ) 
			)
		);
	}
}

sub allow_retry_tasks
{
	my( $self ) = @_;
	return $self->allow( "indexer/retry_tasks" );
}

sub action_retry_tasks
{
	my( $self ) = @_;

	my $abortive_tasks = $self->_get_abortive_tasks;
	$abortive_tasks->map( sub {
		my ( $session, undef, $task ) = @_;

		$task->set_value( 'status', 'waiting' );
		$task->commit;
	} );
}

sub allow_clear_tasks
{
	my( $self ) = @_;
	return $self->allow( "indexer/clear_tasks" );
}

sub action_clear_tasks
{
	my( $self ) = @_;

	my $abortive_tasks = $self->_get_abortive_tasks;
	$abortive_tasks->map( sub {
		my ( $session, undef, $task ) = @_;

		$task->delete;
	} );
}

sub _get_abortive_tasks
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $event_queue = $session->dataset( 'event_queue' );

	my $failed_ids = $event_queue->search(
		filters => [
			{
				meta_fields => [ 'status' ],
				value => 'failed',
			}
		]
	)->ids;

	# Time it would take for standard dequeue of 10 tasks to timeout. Anything older in progress must have gone stale.
	my $stale_seconds =  $session->config( 'indexer_daemon', 'timeout' ) * 10;
	my $stale_time = time() - $stale_seconds;
	my $datetime_less_than_stale_seconds = '-' . EPrints::Time::iso_datetime( time() - $stale_seconds );
	my $stale_ids = $event_queue->search(
		filters => [
			{
				meta_fields => [ 'status' ],
				value => 'inprogress',
			},
			{
				meta_fields => [ 'start_time' ],
				value => $datetime_less_than_stale_seconds,
				match => "EQ",
			},
		]
	)->ids;

	my $ids = [ @$failed_ids, @$stale_ids ];
	return $event_queue->list( $ids );
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
