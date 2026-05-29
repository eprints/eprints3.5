=head1 NAME

EPrints::Plugin::Export::HTML

=cut

package EPrints::Plugin::Export::HTML;

# eprint needs magic documents field

# documents needs magic files field

use EPrints::Plugin::Export::HTMLFile;

@ISA = ( "EPrints::Plugin::Export::HTMLFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "HTML Citation";
	$self->{accept} = [ 'dataobj/eprint', 'dataobj/organisation', 'dataobj/person','list/eprint', 'list/organisation', 'list/person' ];
	$self->{visible} = "all";
	$self->{suffix} = ".html";
	$self->{mimetype} = "text/html; charset=utf-8";
	
	return $self;
}


sub output_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $xml = $plugin->xml_dataobj( $dataobj );

	return EPrints::XML::to_string( $xml, undef, 1 );
}


sub xml_dataobj
{
	my( $plugin, $dataobj ) = @_;

	my $p = $plugin->{session}->make_element( "p", class=>"citation" );

	if ( defined $dataobj && defined $dataobj->{dataset} && $dataobj->{dataset}->has_citation( 'export' ) )
	{
		$p->appendChild( $dataobj->render_citation_link( 'export' ) );
	}
	else
	{
		$p->appendChild( $dataobj->render_citation_link );
	}

	return $p;
}


1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
