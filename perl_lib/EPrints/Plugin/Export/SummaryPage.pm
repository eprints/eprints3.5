=head1 NAME

EPrints::Plugin::Export::SummaryPage

=cut

package EPrints::Plugin::Export::SummaryPage;

use EPrints::Plugin::Export::HTMLFile;

@ISA = ( "EPrints::Plugin::Export::HTMLFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name} = "Summary Page";
	$self->{accept} = [];
	$self->{visible} = "all";
	$self->{advertise} = 0;
	$self->{qs} = 0.9;
	$self->{produce} = [
			"text/html;charset=utf-8",
			"application/xhtml+xml;charset=utf-8",
			$self->mime_type,
		];

	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj, %opts ) = @_;

	my $repo = $self->{session};

	return "" if !$repo->get_online;

	my $title = $dataobj->render_citation( "summary_title" );
	my $page = $dataobj->render_citation( "summary_page" );
	$repo->build_page( $title, $page, "export" );
	$repo->send_page;

	return "";
}

sub output_list
{
	my( $self, %opts ) = @_;

	my $repo = $self->{session};

	return "" if !$repo->get_online;

	my $page = $repo->xml->create_document_fragment;
	$opts{list}->map(sub {
		(undef, undef, my $dataobj) = @_;

		my $para = $page->appendChild( $repo->xml->create_element( "p" ) );
		$para->appendChild( $dataobj->render_citation_link );
	});

	$repo->build_page( undef, $page, "export" );
	$repo->send_page;

	return "";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
