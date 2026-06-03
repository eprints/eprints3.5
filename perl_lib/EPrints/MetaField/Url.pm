######################################################################
#
# EPrints::MetaField::Url;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Url> - no description

=head1 DESCRIPTION

Contains a URL that is turned into a hyperlink when rendered. Same length as a L<EPrints::MetaField::Longtext>.

=over 4

=cut

package EPrints::MetaField::Url;

use EPrints::MetaField::Longtext; # get_sql_type
use EPrints::MetaField::Id;
@ISA = qw( EPrints::MetaField::Id );

use strict;

sub get_sql_type
{
	my( $self, $session ) = @_;

	return $self->EPrints::MetaField::Longtext::get_sql_type( $session );
}

sub sql_row_from_value
{
	my( $self, $session, $value ) = @_;

	return undef unless defined $value;
	# Prevent 'javascript:' links from being saved as there are no benevolent
	# uses for them.
	return undef if $value =~ /^\s*javascript:/;

	return $self->SUPER::sql_row_from_value( $session, $value );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = (
		$self->SUPER::get_property_defaults, # Id
		$self->EPrints::MetaField::Longtext::get_property_defaults, # LongText - maxlength
		match => "IN",
		sql_index => $EPrints::MetaField::FALSE,
		text_index => $EPrints::MetaField::TRUE,
	);
	$defaults{render_dont_link} = $EPrints::MetaField::FALSE;
	return %defaults;
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;

	my $text = $session->make_text( $value );

	return $text if( $self->{render_dont_link} );

	my $link = $session->render_link( $value );
	$link->appendChild( $text );
	return $link;
}

sub get_xml_schema_type
{
	return "xs:anyURI";
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	return $session->make_doc_fragment;
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
