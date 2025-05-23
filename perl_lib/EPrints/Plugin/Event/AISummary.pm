=head1 NAME

EPrints::Plugin::Event::AISummary

=cut

package EPrints::Plugin::Event::AISummary;

@ISA = qw( EPrints::Plugin::Event );

use HTTP::Tiny;

use strict;
use warnings;

sub generate
{
	my( $self, $eprint ) = @_;

	my $repo = $self->{repository};

	my $url = $repo->config( 'ai_summary_endpoint' );
	my %eprint_fields = %{$repo->config( 'ai_summary_fields' )};
	my %auth_fields = %{$repo->config( 'ai_summary_auth_fields' )};

	my %fields;
	for my $field ( keys %eprint_fields ) {
		$fields{$field} = $eprint->get_value( $eprint_fields{$field} );
	}
	for my $field ( keys %auth_fields ) {
		$fields{$field} = $auth_fields{$field};
	}

	my $http = HTTP::Tiny->new;
	my $params = $http->www_form_urlencode( \%fields );

	my $response = $http->get( "$url?$params" );
	my $content = $response->{content};
	utf8::decode( $content );

	my $hash = JSON->new->decode($content);

	my %output_fields = %{$repo->config( 'ai_summary_output_fields' )};
	for my $key ( keys %{$hash} ) {
		if( defined $output_fields{$key} ) {
			$eprint->set_value( $output_fields{$key}, $hash->{$key} );
		}
	}
	$eprint->commit;

	return;
}

1;
