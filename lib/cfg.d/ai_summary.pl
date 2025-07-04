$c->{ai_summary_enabled} = 0;

# If the summary is enabled you will need to add some fields to the eprints,
#  these are the recommended fields if you are using these settings:
# push @{$c->{fields}->{eprint}},
# {
#     name => 'ai_summary',
#     type => 'longtext',
# },
# {
#     name => 'ai_topics',
#     type => 'text',
#     render_value => 'render_ai_topic_links',
# };

# The endpoint to call when requesting an AI summary (must be accessible by the server)
$c->{ai_summary_endpoint} = '<Override this with your AI endpoint>';

# Maps url arguments to the EPrint fields to fill them with when calling the AI endpoint (e.g. ...?q=<abstract>)
$c->{ai_summary_fields} = {
	q => 'abstract',
};

# Defines extra arguments to pass to the AI endpoint (e.g. ...?password=supersecret)
$c->{ai_summary_auth_fields} = {
	password => 'supersecret',
};

# Maps the JSON names returned by the AI endpoint to fields on the EPrint
$c->{ai_summary_output_fields} = {
	ai_summary => 'ai_summary',
	ai_topics => 'ai_topics',
};

# A render_value function to convert a comma separated string of topics into a group of links to their relevant searches
use HTTP::Tiny;
$c->{render_ai_topic_links} = sub {
	my( $session, $self, $value, $all_langs, $no_link, $object ) = @_;

	# Don't make 'Use of uninitialized value' warnings if 'ai_topic' is unset
	return undef if !defined $value;

	my $http_tiny = HTTP::Tiny->new;

	my $span = $session->make_element( 'span' );
	my $first_loop = 1;
	for my $topic (split ',', $value) {
		$span->appendChild( $session->make_text( ', ' ) ) if !$first_loop;

		if( $no_link ) {
			$span->appendChild( $session->make_text( $topic ) );
		} else {
			my $query = $http_tiny->www_form_urlencode( { q => $topic } );
			my $link = $span->appendChild( $session->render_link( $c->{perl_url} . '/search/simple?' . $query ) );
			$link->appendChild( $session->make_text( $topic ) );
		}

		$first_loop = 0;
	}
	return $span;
}
