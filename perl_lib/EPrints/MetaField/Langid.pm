######################################################################
#
# EPrints::MetaField::Langid
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Langid> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Langid;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Set );
}

use EPrints::MetaField::Set;


sub get_sql_type
{
	my( $self, $session ) = @_;

	return $session->get_database->get_column_type(
		$self->get_sql_name(),
		EPrints::Database::SQL_VARCHAR,
		!$self->get_property( "allow_null" ),
		16,
		undef,
		$self->get_sql_properties,
	);
}


sub render_option
{
	my( $self, $session, $option ) = @_;

	$option = "" if !defined $option;

	my $phrasename = "languages_typename_".$option;

	# if the option is empty, and no explicit phrase is defined, print 
	# UNDEFINED rather than an error phrase.
	if( $option eq "" && !$session->get_lang->has_phrase( $phrasename, $session ) )
	{
		$phrasename = "lib/metafield:unspecified";
	}

	return $session->html_phrase( $phrasename );
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	return %defaults;
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
