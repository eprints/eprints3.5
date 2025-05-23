package EPrints::Plugin::Screen::EPrint::Staff::GenerateAISummary;

@ISA = ( 'EPrints::Plugin::Screen::EPrint' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );
	my $repo = $self->{repository};

	if( $repo->config( 'ai_summary_enabled' ) ) {
		$self->{actions} = [qw/ generate remove /];

		$self->{appears} = [
			{
				place => 'eprint_editor_actions',
				action => 'generate',
				position => 1934,
			},
			{
				place => 'eprint_editor_actions',
				action => 'remove',
				position => 1957,
			},
		];
	}

	return $self;
}

sub about_to_render
{
	my( $self ) = @_;

	$self->EPrints::Plugin::Screen::EPrint::View::about_to_render;
}

sub allow_generate
{
	my( $self ) = @_;

	return $self->allow( 'eprint/edit:editor' );
}

sub action_generate
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $eprint = $self->{processor}->{eprint};

	EPrints::DataObj::EventQueue->create_unique( $repo, {
		pluginid => 'Event::AISummary',
		action => 'generate',
		params => [ $eprint->internal_uri ],
		userid => $repo->current_user->id,
	});

	$self->{processor}->add_message( 'message', $repo->html_phrase( 'Plugin/Screen/EPrint/Staff/GenerateAISummary:action:generate:message' ) );
}

sub allow_remove
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $eprint = $self->{processor}->{eprint};

	return 0 unless $self->could_obtain_eprint_lock;

	for my $field (keys %{$repo->config( 'ai_summary_output_fields' )}) {
		return $self->allow( 'eprint/edit:editor' ) if $eprint->get_value( $field );
	}
	return 0;
}

sub action_remove
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $eprint = $self->{processor}->{eprint};

	for my $field (keys %{$repo->config( 'ai_summary_output_fields' )}) {
		$eprint->set_value( $field, undef );
	}
	$eprint->commit;

	$self->{processor}->add_message( 'message', $repo->html_phrase( 'Plugin/Screen/EPrint/Staff/GenerateAISummary:action:remove:message' ) );
}

1;
