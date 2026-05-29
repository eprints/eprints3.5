######################################################################
#
# EPrints::MetaField::Timestamp;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Timestamp> - a date/time

=head1 DESCRIPTION

A date/time that defaults to the current time in UTC.

=over 4

=cut


package EPrints::MetaField::Timestamp;

use strict;
use warnings;

use EPrints::MetaField::Time;
our @ISA = qw( EPrints::MetaField::Time );

sub get_default_value
{
	return EPrints::Time::get_iso_timestamp();
}

sub is_type
{
	my( $self, @types ) = @_;

	for(@types)
	{
		return 1 if $_ eq "time";
		return 1 if $_ eq "timestamp";
	}

	return 0;
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
