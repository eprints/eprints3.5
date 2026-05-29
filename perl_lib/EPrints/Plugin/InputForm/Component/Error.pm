=head1 NAME

EPrints::Plugin::InputForm::Component::Error

=cut

package EPrints::Plugin::InputForm::Component::Error;

use EPrints::Plugin::InputForm::Component;

@ISA = ( "EPrints::Plugin::InputForm::Component" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Error";
	$self->{visible} = "all";

	return $self;
}

sub is_collapsed { 0 }

sub render_content
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $frag = $xml->create_document_fragment;

	my @problems = $self->problems;

	if( @problems == 1 )
	{
		$frag->appendChild( $problems[0] );
	}
	elsif( @problems > 1 )
	{
		my $ul = $frag->appendChild( $xml->create_element( "ul" ) );
		foreach my $problem (@problems)
		{
			my $li = $ul->appendChild( $xml->create_element( "li" ) );
			$li->appendChild( $problem );
		}
	}

	return $repo->render_message( "warning", $frag );
}

sub render_help
{
	my( $self, $surround ) = @_;
	
	return $self->html_phrase( "help" );
}

sub render_title
{
	my( $self, $surround ) = @_;

	my $workflow = $self->{workflow};
	my $datasetid = $workflow->{dataset}->base_id;
	my $workflowid = $workflow->{workflow_id};
	my $filename = $self->{repository}{workflows}{$datasetid}{$workflowid}{file};

	return $self->html_phrase( "title",
		filename => $self->{repository}->xml->create_text_node( $filename ),
	);
}
	
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
