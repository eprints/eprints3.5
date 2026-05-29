=head1 NAME

EPrints::Plugin::Export::Urls

=cut

package EPrints::Plugin::Export::Urls;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = 'Document URLs';
	$self->{accept} = [ 'list/eprint', 'dataobj/eprint' ];
	$self->{visible} = 'all';
	$self->{suffix} = '.html';
	$self->{mimetype} = 'text/html; charset=utf-8';
	
	return $self;
}

sub output_dataobj
{
	my( $plugin, $eprint ) = @_;

	my $links = '';

	for my $document ($eprint->get_all_documents) {
		next unless $document->is_public || $document->user_can_view( $plugin->{repository}->current_user );

		$links .= '<a href="' . $document->get_url . '">' . $document->get_url . '</a>';
		$links .= ' (private)' unless $document->is_public;
		$links .= '<br />';
	}

	return $links;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
