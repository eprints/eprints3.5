$c->add_dataset_trigger( 'organisation', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_;

	my( $organisation, $changed ) = @args{qw( dataobj changed )};

	my $ds = $organisation->dataset;

	if( $organisation->is_set( "ids" ) )
	{
		my $found = 0;
		foreach my $id_type ( @{$ds->get_field( 'ids_id_type' )->get_values} )
		{
			foreach my $id ( @{$organisation->get_value( 'ids' )} )
			{
				if ( $id->{id_type} eq $id_type )
				{
					$organisation->set_value( 'id_value', $id->{id} );
					$organisation->set_value( 'id_type', $id->{id_type} );
					$found = 1;
					last;
				}
			}
			last if $found;
		}
	}
	else
	{
		$organisation->set_value( 'id_value', undef );
		$organisation->set_value( 'id_type', undef );
	}

	if( $organisation->is_set( "names" ) )
	{
		foreach my $name ( @{$organisation->get_value( 'names' )} )
		{
			if ( ! EPrints::Utils::is_set( $name->{to} ) )
			{
				$organisation->set_value( 'name', $name->{name} );
				last;
			}
		}
	}
	else
	{
		$organisation->set_value( 'name', undef );
	}

},  id => 'update_id_and_name_fields', priority => 100 );


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

