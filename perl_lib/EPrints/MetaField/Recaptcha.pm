######################################################################
#
# EPrints::MetaField::Recaptcha;
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Recaptcha3> - a Captcha using Google ReCAPTCHA v2.

=head1 DESCRIPTION

This metadata field renders a Captcha (a test that humans can easily
pass, but robots shouldn't be able to).

Please refer to the wiki page L<https://wiki.eprints.org/w/Recaptcha_field>
for advice on how to configure settings required for this field to work.

The following configuration settings will be required, where the C<CHANGME>
settings will need to be updated with the secret and site keys provided
by Google:

 $c->{recaptcha}->{private_key} = "CHANGEME";
 $c->{recaptcha}->{public_key} = "CHANGEME";
This field uses version 2 of Google "reCAPTCHA" service:

L<https://developers.google.com/recaptcha/docs/display>

Please use the URL above for guidance on how to generate appropriate
keys needed to configure this type of field.

Note: 
This MetaField was updated in October 2017 to reCAPTCHA v2.
The previous version of reCAPTCHA will cease to work in March 2018.

Kudos to Matthew Kerwin (https://github.com/phluid61) for most of the work on the new version.

=head1 INHERITANCE

 L<EPrints::MetaField>
   L<EPrints::MetaField::Id>
     B<EPrints::MetaField::Recaptcha>

=cut

package EPrints::MetaField::Recaptcha;

use EPrints::MetaField::Id;
@ISA = qw( EPrints::MetaField::Id );

use strict;
use JSON;



sub is_virtual { 1 }

sub render_input_field_actual
{
	my( $self, $session, $value, $dataset, $staff, $hidden_fields, $obj, $basename ) = @_;

	my $public_key = $session->config( "recaptcha", "public_key" );

	if( !defined $public_key )
	{
		return $session->render_message( "error", $session->make_text( "public_key not set" ) );
	}

	my $frag = $session->make_doc_fragment;

	my $url = URI->new( "https://www.google.com/recaptcha/api.js" );

	$frag->appendChild( $session->make_javascript( undef,
		src => $url,
		async => 'async',
		defer => 'defer'
	) );

	$frag->appendChild( $session->make_element( "div",
		class => "g-recaptcha",
		'data-sitekey' => $public_key,
	) );

	# No-Script, for users with javascript disabled
	$url = URI->new( "https://www.google.com/recaptcha/api/fallback" );
	$url->query_form( k => $public_key );

	my $noscript = $frag->appendChild( $session->make_element( "noscript" ) );
	$noscript->appendChild( $session->make_element( "iframe",
		src => $url,
		height => "422",
		width => "302",
		frameborder => "0"
	) );
	$noscript->appendChild( $session->make_element( "br" ) );
	$noscript->appendChild( $session->make_element( "textarea",
		id => "g-recaptcha-response",
		name => "g-recaptcha-response",
		rows => "3",
		cols => "40"
	) );

	return $frag;
}

sub form_value_actual
{
	my( $self, $repo, $object, $basename ) = @_;

	my $private_key = $repo->config( "recaptcha", "private_key" );
	my $timeout = $repo->config( "recaptcha", "timeout" ) || 5;

	if( !defined $private_key )
	{
		$repo->log( "recaptcha private_key not set" );
		return undef;
	}

	my $response = $repo->param( "g-recaptcha-response" );
	if( !EPrints::Utils::is_set( $response ) )
	{
		if ( my $ignore_countries = $repo->config( "recaptcha", "ignore_countries" ) )
                {
                        # if possible, use the GeoIP data file shipped with EPrints
                        my $dat_file = $repo->config( "lib_path").'/geoip/GeoIP.dat';

                        # alternatively use the global one
                        $dat_file = 1 if( !-e $dat_file );

                        #Test Geo::IP first - it's faster!
                        my $geoip;
                        foreach my $pkg ( 'Geo::IP', 'Geo::IP::PurePerl' )
                        {
                                if( EPrints::Utils::require_if_exists( $pkg ) )
                                {
                                        $geoip = $pkg->new( $dat_file );
                                        last if( defined $geoip );
                                }
                        }
                        if ( defined $geoip )
                        {
                                my $code = $geoip->country_code_by_addr( $repo->remote_ip ); 
                                if ( grep { $_ eq $code } @{ $ignore_countries } )
                                {
                                        $repo->log( "NOTICE: No ReCAPTCHA used for IP address ".$repo->remote_ip." from $code." );
                                        return undef;
                                }
                        }
                }
		return "invalid-captcha-sol";
	}

	my $url = URI->new( "https://www.google.com/recaptcha/api/siteverify" );

	my $ua = LWP::UserAgent->new();
	$ua->env_proxy;
	$ua->timeout( $timeout ); #LWP default timeout is 180 seconds. 

	my $r = $ua->post( $url, [
		secret => $private_key,
		response => $response
	]);

	# the request returned a response - but we have to check whether the human (or otherwise)
	# passed the Captcha 
	if( $r->is_success )
	{
		my $hash = decode_json( $r->content );
		if( !$hash->{success} )
		{
			my $recaptcha_error = 'unknown-error';
			my $codes = $hash->{'error-codes'};
			if( $codes && scalar @{$codes} )
			{
				$recaptcha_error = join '+', @{$codes};
			}
			return $recaptcha_error;
		}
		return undef; #success!
	}

	# error talking to recaptcha, so lets continue to avoid blocking the user
	# in case of network problems
	$repo->log( "Error contacting recaptcha: ".$r->code." ".$r->message );

	return undef;
}

sub validate
{
	my( $self, $session, $value, $object ) = @_;

	my @probs;

	if( $value )
	{
		push @probs, $session->html_phrase( "validate:recaptcha_mismatch" );
	}

	return @probs;
}

######################################################################
1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=end LICENSE
