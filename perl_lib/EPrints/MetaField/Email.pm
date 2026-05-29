######################################################################
#
# EPrints::MetaField::Email;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Email> - no description

=head1 DESCRIPTION

Contains an Email address that is linked when rendered.

=over 4

=cut

package EPrints::MetaField::Email;

use EPrints::MetaField::Idci;
@ISA = qw( EPrints::MetaField::Idci );

use strict;

sub get_property_defaults
{
	my( $self ) = @_;

	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{render_dont_link} = $EPrints::MetaField::FALSE;

	return %defaults;
}

sub render_single_value
{
	my( $self, $session, $value ) = @_;
	
	return $session->make_doc_fragment if !EPrints::Utils::is_set( $value );

	my $text = $session->make_text( $value );

	return $text if !defined $value;
	return $text if( $self->{render_dont_link} );

	my $link = $session->render_link( "mailto:".$value );
	$link->appendChild( $text );
	return $link;
}

sub validate
{
        my( $self, $session, $value, $object ) = @_;

	# closure for generating the field link fragment
        my $f_fieldname = sub {
                my $f = defined $self->property( "parent" ) ? $self->property( "parent" ) : $self;
                my $fieldname = $session->xml->create_element( "span", class=>"ep_problem_field:".$f->get_name );
                $fieldname->appendChild( $f->render_name( $session ) );
                return $fieldname;
        };

        my @probs = $self->SUPER::validate( $session, $value, $object );

	my $values = ( ref $value eq "ARRAY" ? $value : [ $value ] );

        for my $value ( @{$values} )
        {
		push @probs, $session->html_phrase( "validate:bad_email", fieldname =>  &$f_fieldname ) if defined $value && !EPrints::Utils::validate_email( $value );
	}

	return @probs;
}

######################################################################
1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
