
# Internal log handling
#  Enables a hook into Apache to catch logging events and
#  record them directly into the eprints database for usage analysis

# set this to 1 to enable log handling
# (then run generate_apacheconf and restart apache)
$c->{loghandler}->{enable} = 1;

# Log timings on submissions. 
# This feature creates a log file in the eprints var directory
# which logs timestamps of users doing the submission process. It's
# useful for us to monitor time taken on various pages in the submission
# process and maybe you want to to...
# Uncomment to enable.
# $c->{log_submission_timing} = 1; 

# Uncomment to include timestamps in logged messages
# $c->{show_timestamps_in_log} = 1;

# Uncomment to include the repository archive ID in logged messages
# $c->{show_ids_in_log} = 1;


######################################################################
#
# EP_TRIGGER_LOG replaces log( $repository, $message )
#
######################################################################
# $repository 
# - repository object
# $message 
# - log message string
#
######################################################################
# This method is called to log something important. By default it 
# sends everything to STDERR which means it ends up in the apache
# error log ( or just stderr for the command line scripts in bin/ )
# If you want to write to a file instead, or add extra information 
# such as the name of the repository, this is the place to do it.
#
######################################################################

$c->add_trigger( EP_TRIGGER_LOG,
	sub {
		my %params = @_;
		my $repo = $params{repository};
		my $message = $params{message};

		if ( $repo->can_call( 'log' ) ) {
			$repo->call( 'log', $repo, "UPGRADE: configuration uses 'log'. Please review upgrade advice for trigger 'EP_TRIGGER_LOG'." );
			$repo->call( 'log', $repo, $message );
		} else {
			print STDERR $message . "\n";

			# You may wish to use this line instead if you have many repositories,
			# but if you only have one then it's just more noise.
			# print STDERR "[".$repo->get_id()."] ".$message."\n";
		}
	},
	priority => 1,
	id => 'log',
);

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
