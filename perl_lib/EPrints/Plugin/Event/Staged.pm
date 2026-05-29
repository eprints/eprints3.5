=head1 NAME

EPrints::Plugin::Event::Staged

=cut

package EPrints::Plugin::Event::Staged;

use EPrints::Plugin::Event;

@ISA = qw( EPrints::Plugin::Event );

sub new
{
        my( $class, %params ) = @_;

        $params{staged} = 1; 

        return $class->SUPER::new(%params);
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
