######################################################################
#
# EPrints::MetaField::Namedset;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Namedset> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

# set_name

package EPrints::MetaField::Namedset;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Set );
}

use EPrints::MetaField::Set;

sub tags
{
	my( $self ) = @_;

	if( defined $self->{options} )
	{
		return @{$self->{options}};
	}
	return $self->{repository}->get_types( $self->{set_name} );
}

sub tag_groups
{
    my( $self ) = @_;

    return $self->{repository}->get_type_groups( $self->{set_name} );
}

sub tags_and_labels
{
    my( $self , $session ) = @_;
    my @tags = $self->tags( $session );
    my %labels = ();

    foreach( @tags )
    {
        $labels{$_} = EPrints::Utils::tree_to_utf8(
            $self->render_option( $session, $_ ) );
    }

	my @tag_groups = $self->tag_groups( $session );
	my @groups = ();
	foreach( @tag_groups )
	{
		push @groups, {
			label => EPrints::Utils::tree_to_utf8( $self->render_option_group( $session, $_->{id} ) ),
			options => $_->{types},
		};
	}

	if( $self->get_property( 'order_labels' ) )
	{
		# Order the labels alphabetically
		my @otags = sort { $a ne 'other' && $b ne 'other' && ($labels{$a} cmp $labels{$b}) } @tags;
		return (\@otags, \%labels );
	}

    return (\@tags, \%labels, \@groups );
}



sub get_unsorted_values
{
	my( $self, $session, $dataset, %opts ) = @_;

	if( defined $self->{options} )
	{
		return @{$self->{options}};
	}
	my @types = $self->{repository}->get_types( $self->{set_name} );

	return @types;
}

sub render_option
{
	my( $self, $session, $value ) = @_;

	if( !defined $value )
	{
		return $self->SUPER::render_option( $session, $value );
	}

        if( defined $self->get_property("render_option") )
        {
                return $self->call_property( "render_option", $session, $value );
        }

	return $session->render_type_name( $self->{set_name}, $value );
}

sub render_option_group
{
    my( $self, $session, $value ) = @_;

    if( defined $self->get_property("render_option_group") )
    {
        return $self->call_property( "render_option_group", $session, $value );
    }

    return $session->render_type_group_name( $self->{set_name}, $value );
}


sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{set_name} = $EPrints::MetaField::REQUIRED;
	$defaults{options} = $EPrints::MetaField::UNDEF;
	$defaults{render_option_group} = $EPrints::MetaField::UNDEF;
	return %defaults;
}

sub get_search_group { return 'set'; }

=item $ov = $field->ordervalue_basic( $value, $session, $langid )

Return $value as an order value that will be cmp().

For Namedset this returns the values in the order they are given in the named set.

=cut

sub ordervalue_basic
{
	my( $self, $value, $session, $langid ) = @_;

	my @types = $self->tags( $session );
	foreach my $i (0..$#types)
	{
		return sprintf("%06d", $i)
			if $types[$i] eq $value;
	}

	# this will always come after any known values
	return $value;
}


######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
