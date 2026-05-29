######################################################################
#
# EPrints::MetaField::Float;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Float> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Float;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Int );
}

use EPrints::MetaField::Int;

# does not yet support searching.

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_REAL,
		!$self->get_property( "allow_null" ),
		undef,
		undef,
		$self->get_sql_properties,
	);
}

sub ordervalue_basic
{
	my( $self , $value ) = @_;

	my $regexp = defined $self->property( 'regexp' ) ? $self->property( 'regexp' ) : '.*';
	unless( EPrints::Utils::is_set( $value ) || $value =~ /^($regexp)$/ )
	{
		return "";
	}

	return sprintf( "%020f", $value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{text_index} = 0;
	$defaults{regexp} = qr/-?[0-9]+(\.[0-9]+)?/;
	return %defaults;
}

sub get_xml_schema_type
{
	return "xs:double";
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	return $session->make_doc_fragment;
}

sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge, $search_mode ) = @_;

	my %defaults = $self->get_property_defaults;
	my $number = $defaults{regexp};
	if( $search_value =~ m/^$number$/ )
	{
		my @r = ();
		push @r, EPrints::Search::Condition->new(
			'>=',
			$dataset,
			$self,
			$search_value - 0.00001);
		push @r, EPrints::Search::Condition->new(
			'<=',
			$dataset,
			$self,
			$search_value + 0.00001);
		return EPrints::Search::Condition->new( "AND", @r );
	}

	return $self->SUPER::get_search_conditions_not_ex( $session, $dataset, $search_value, $match, $merge, $search_mode );
}

sub empty_value
{
    my ( $self ) = @_;
    $self->property( 'allow_null' ) == 1 ? undef : 0;
}

sub sql_row_from_value
{
	my( $self, $session, $value ) = @_;

	my $regexp = defined $self->property( 'regexp' ) ? $self->property( 'regexp' ) : '.*';
	if ( defined $value && $value !~ m/^($regexp)$/ )
	{
		$value = undef;
		$session->log( "WARNING: Value for field '".$self->name."' as it is not a valid floating point number or does not match field's regexp." );
	}

	return( $value );
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
