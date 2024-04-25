######################################################################
#
# EPrints::RepositoryConfig
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::RepositoryConfig> - Repository Configuration

=head1 SYNOPSIS

	$c->add_dataset_field( "eprint", {
		name => "title",
		type => "longtext",
	}, reuse => 1 );
	
	$c->add_trigger( EP_TRIGGER_URL_REWRITE, sub {
		my( %params ) = @_;
	
		my $r = $params{request};
	
		my $uri = $params{uri};
		if( $uri =~ m{^/blog/} )
		{
			$r->err_headers_out->{Location} = "http://...";
			${$params{rc}} = EPrints::Const::HTTP_SEE_OTHER;
			return EP_TRIGGER_DONE;
		}
	
		return EP_TRIGGER_OK;
	});

=head1 DESCRIPTION

This provides methods for reading and setting a repository configuration.
Setter methods may only be used in the configuration.

=head1 METHODS

=head2 Setter Methods

=over 4

=cut

package EPrints::RepositoryConfig;

use strict;

=item $c->add_dataset_trigger( $datasetid, TRIGGER_ID, $f, %opts )

Register a function reference $f to be called when the TRIGGER_ID event happens on $datasetid.

See L<EPrints::Const> for available triggers.

See L</add_trigger> for %opts.

=cut

sub add_dataset_trigger
{
	my( $self, $datasetid, $type, $f, %opts ) = @_;

	if( $self->read_only ) { EPrints::abort( "Configuration is read-only." ); }

	if( ref($f) ne "CODEREF" && ref($f) ne "CODE" )
	{
		EPrints->abort( "add_dataset_trigger expected a CODEREF but got '$f'" );
	}

	my $priority = exists $opts{priority} ? $opts{priority} : 0;

	my $id = determine_trigger_id( $opts{id}, $f );

	$self->{datasets}->{$datasetid}->{triggers}->{$type}->{$priority}->{$id} = $f;
}

=item $c->add_trigger( TRIGGER_ID, $f, %opts )

Register a function reference $f to be called when the TRIGGER_ID event happens.

See L<EPrints::Const> for available triggers.

Options:

	priority - used to determine the order triggers are executed in (defaults to 0).

=cut

sub add_trigger
{
	my( $self, $type, $f, %opts ) = @_;

	if( $self->read_only ) { EPrints::abort( "Configuration is read-only." ); }

	if( ref($f) ne "CODEREF" && ref($f) ne "CODE" )
	{
		EPrints->abort( "add_trigger expected a CODEREF but got '$f'" );
	}

	my $priority = exists $opts{priority} ? $opts{priority} : 0;

	my $id = determine_trigger_id( $opts{id}, $f );

	$self->{triggers}->{$type}->{$priority}->{$id} = $f;
}

=item EPrints::RepositoryConfig::determine_triggerid ( $trigger_id, $code )

Generates an ID for a trigger so it can be individually referenced.  If C<$trigger_id> is non-empty
use this. If not, if C<B::Deparse> library is available and C<$code> is a code reference generate
an md5sum of the function as a string. Otherwose just generate a random UUID.

Returns the generated ID for the trigger.

=cut

sub determine_trigger_id
{
	my( $trigger_id, $code ) = @_;
	
	return $trigger_id if $trigger_id;

	if ( EPrints::Utils::require_if_exists( 'B::Deparse' ) )
	{
		my $deparse = B::Deparse->new( "-p", "-sC" );
		return Digest::MD5::md5_hex( $deparse->coderef2text( $code ) );
	}
	
	$trigger_id .= sprintf("%x", rand 16) for 1..32;
	return $trigger_id;
}

=item $c->add_dataset_field( $datasetid, $fielddata, %opts )

Add a field spec $fielddata to dataset $datasetid.

This method will abort if the field already exists and 'reuse' is unspecified.

Options:
	reuse - re-use an existing field if it exists (must be same type)

=cut

sub add_dataset_field
{
	my( $c, $datasetid, $fielddata, %opts ) = @_;

	$c->{fields}->{$datasetid} = [] if !exists $c->{fields}->{$datasetid};

	my $reuse = $opts{reuse};

	for(@{$c->{fields}->{$datasetid}})
	{
		if( $_->{name} eq $fielddata->{name} )
		{
			if( !$reuse )
			{
				EPrints->abort( "Duplicate field name encountered in configuration: $datasetid.$_->{name}" );
			}
			elsif( $_->{type} ne $fielddata->{type} )
			{
				EPrints->abort( "Attempt to reuse field $datasetid.$_->{name} but it is a different type: $_->{type} != $fielddata->{type}" );
			}
			else
			{
				return;
			}
		}
	}

	push @{$c->{fields}->{$datasetid}}, $fielddata;
}

=pod

=back

=cut 

# Non advertised methods!

sub set_read_only
{
	my( $self ) = @_;
	$self->{".read_only"} = 1;	
}

sub unset_read_only
{
	my( $self ) = @_;
	$self->{".read_only"} = 0;	
}

sub read_only
{
	my( $self ) = @_;

	return( defined $self->{".read_only"} && $self->{".read_only"} );
}

1;

=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

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

=for LICENSE END

