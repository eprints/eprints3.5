######################################################################
#
# EPrints::MetaField::Relation;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Relation> - Subclass of compound for relations

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Relation;

use EPrints::MetaField::Compound;

@ISA = qw( EPrints::MetaField::Compound );

use strict;

sub new
{
	my( $self, %params ) = @_;

	$params{fields} = [
		{ sub_name=>"type", type=>"id", },
		{ sub_name=>"uri", type=>"id", },
	];

	return $self->SUPER::new( %params );
}

sub to_sax_basic
{
	my( $self, $value, %opts ) = @_;

	return unless EPrints::Utils::is_set( $value ) && EPrints::Utils::is_set( $value->{uri} );

	return $self->SUPER::to_sax_basic( {
		type => $value->{type},
		uri => $self->{repository}->config( "base_url" ) . $value->{uri},
	}, %opts );
}

######################################################################

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
