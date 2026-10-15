######################################################################
#
# EPrints::Index::Daemon
#
######################################################################
#
#
######################################################################


=pod

=head1 NAME

B<EPrints::Index::Daemon> - indexer process

=head1 DESCRIPTION

This module provides utility wrappers around the indexing engine to provide a
daemonised service.

You probably don't want to use anything here directly, instead use the
B<bin/indexer> script or L<EPrints::Plugin::Screen::Admin::IndexerControl>.

=head1 METHODS

=over 4

=cut


package EPrints::Index::Daemon;

use EPrints;

use strict;

=head2 Class Methods

=cut

=item EPrints::Index::Daemon->new( %opts )

Return a new daemon control object. May optionally specify 'session', 'logfile', 'loglevel' and 'Handler' to control log output.

=cut

sub new
{
	my( $class, %opts ) = @_;

	$opts{suicidefile} ||= EPrints::Index::suicidefile();

	# process only one set of events, then quit
	$opts{once} ||= 0;

	# Get options for SystemSettings if not already set
	my $settings = $EPrints::SystemSettings::conf->{indexer_daemon};
	foreach my $setting ( keys %$settings )
	{
		$opts{$setting} ||= $settings->{$setting};
	}
	
	# Get options for hardcoded defaults if still not already set
	$opts{loglevel} ||= 1;
	$opts{maxwait} ||= 8; # 8 seconds
	$opts{interval} ||= 30; # 30 seconds
	$opts{timeout} ||= 600; # 10 minutes


	my $self = bless \%opts, $class;

	return $self;
}

# create the suicide file which will result in the process stopping
sub create_suicide_file
{
	my( $self ) = @_;
	print STDERR "creating " . $self->{suicidefile} . "\n";

	# `touch $self->{suicidefile}`

	open my $file, '>', $self->{suicidefile} or do {
		print STDERR "$0: open " . $self->{suicidefile} . ": $!\n";
		return 0;
	};

	print {$file} EPrints::Time::get_iso_timestamp() . "\n";

	close $file;

	return 1;
}

# return true if we've been asked to exit
sub interrupted
{
	my( $self ) = @_;

	if (-e $self->{suicidefile})
	{
		$self->log( 1, "Suicide file found, creating interrupt" );
		unlink $self->{suicidefile};
		$self->{interrupt} = 1;
	}

	return $self->{interrupt};
}

# Get all sessions for all repositories
sub get_all_sessions
{
	my( $self ) = @_;

	my @repos;

	my $eprints = EPrints->new;

	foreach my $id (sort $eprints->repository_ids)
	{
		my $repository = $eprints->repository( $id );
		if( !defined $repository )
		{
			$self->log( 0, "!! Could not open session for $id" );
			next;
		}
		next unless $repository->config( "index" );
		push @repos, $repository;
	}

	return @repos;
}

=item $daemon->log( LEVEL, MESSAGE )

Prints MESSAGE to STDERR if loglevel >= LEVEL.

=cut

sub log
{
	my( $self, $level, $msg ) = @_;

	return unless $self->{loglevel} >= $level;

	if( !defined $msg )
	{
		print STDERR "\n";
		return;
	}

	print STDERR "[".localtime()."] $$ ".$msg."\n";
}


# Really exit, ignoring mod_perl's pseudo-exit.
sub real_exit
{
	my( $self ) = @_;

	if( $self->{session} and $self->{session}->{request} )
	{
		CORE::exit(0); # exit inside mod_perl
	}
	else
	{
		exit(0);
	}
}


=item $daemon->run_index

Runs a single indexing process for all repositories.

=cut

sub run_index
{
	my( $self ) = @_;

	$self->log( 3, "** Worker process started" );

	my @repos = $self->get_all_sessions();

	$SIG{TERM} = sub {
		$self->log( 3, "** Worker process terminated (SIGTERM)" );
		$self->real_exit;
	};
	$SIG{INT} = sub {
		$self->log( 3, "** Worker process interrupted (SIGINT)" );
		$self->{interrupt} = 1;
	};

	while( 1 )
	{
		my $processed_tasks = 0;

		foreach my $repo ( @repos )
		{
			if ($self->interrupted())
			{
				# break out of processing repos
				last;
			}
			$self->log( 5, "** Processing queue from ".$repo->get_id );

			# (re)init the repository object e.g. reconnect timed-out DBI
			$repo->init_from_indexer( $self );

			# give the next code $timeout secs to complete
			eval {
				local $SIG{ALRM} = sub { die "alarm\n" };
				alarm($self->{timeout});

				$processed_tasks += $self->process_indexer_tasks( $repo );

				alarm(0);
			};
			if( $@ )
			{
				die unless $@ eq "alarm\n";
				$self->log( 1, "** Timed out processing index entry: some indexing failed" );
			}
		}

		if ($self->{once} && $processed_tasks == 0)
		{
			# nothing more to do, break out of forever loop
			last;
		}

		if ( $processed_tasks == 0 )
		{
			$self->log( 3, "No tasks found, sleeping" );

			# clear temporary values, database connection, language
			# if we lose connection while sleeping we can lose any connection
			# settings on an auto-reconnect
			# some session variables may need to clear
			foreach my $repo (@repos)
			{
				$repo->cleanup();
			}

			# wait interval seconds. Check interrupt requests every second.
			my $stime = time();
			while( ($stime + $self->{interval}) > time() )
			{
				if ($self->interrupted())
				{
					# break out of sleeping
					last;
				}
				sleep 1;
			}
		}
		else
		{
			$self->log( 3, "Processed $processed_tasks tasks" );
		}
		if ($self->interrupted())
		{
			# break out of forever loop
			last;
		}
	}

	if( $self->interrupted )
	{
		$self->log( 3, "** Worker process stopping" );
	}
	elsif( !$self->{once} )
	{
		$self->log( 3, "** Worker process restarting" );
	}
	else
	{
		$self->log( 3, "** Worker process finished" );
	}
}

sub process_indexer_tasks
{
	my( $self, $repo ) = @_;

	my $processed_tasks = 0;
	# events are EPrints::DataObj::EventQueue
	my @events = $repo->get_database->dequeue_events( 10 );
	$self->log( 5, "** Empty task list" ) if !@events;
	foreach my $event (@events)
	{
		# reset events on interruption
		if( $self->interrupted() )
		{
			$event->set_value( "status", "waiting" );
			$event->commit( 1 );
			next;
		}
		if( $self->{loglevel} >= 5 )
		{
			my $pluginid = $event->value( "pluginid" );
			my $action = $event->value( "action" );
			my $params = $event->value( "params" );

			my $citation = $event->render_citation();
			$self->log( 5, $repo->get_id.": ".EPrints::Utils::tree_to_utf8( $citation ) );
			$repo->xml->dispose( $citation );
		}
		my $rc = $event->execute();
		$processed_tasks += 1;
		if( $rc == 0 )
		{
			$self->log( 3, "** event ".$event->get_id()." failed" );
		}

	}

	return $processed_tasks; # includes failed
}

1;

=back

=head1 SEE ALSO

L<EPrints::Index>

=cut


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
