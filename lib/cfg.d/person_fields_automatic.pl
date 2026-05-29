$c->add_dataset_trigger( 'person', EPrints::Const::EP_TRIGGER_BEFORE_COMMIT, sub
{
	my( %args ) = @_;

	my( $person, $changed ) = @args{qw( dataobj changed )};

	my $ds = $person->dataset;

	if( $person->is_set( "ids" ) )
	{
		my $found = 0;
		foreach my $id_type ( @{$ds->get_field( 'ids_id_type' )->get_values} )
		{
			foreach my $id ( @{$person->get_value( 'ids' )} )
			{
				if ( $id->{id_type} eq $id_type )
				{
					$person->set_value( 'id_value', $id->{id} );
					$person->set_value( 'id_type', $id->{id_type} );
					$found = 1;
					last;
				}
			}
			last if $found;
		}
	}
	else
	{
		$person->set_value( 'id_value', undef );
		$person->set_value( 'id_type', undef );
	}

	if( $person->is_set( "names" ) )
	{
		foreach my $name ( @{$person->get_value( 'names' )} )
		{
			if ( ! EPrints::Utils::is_set( $name->{to} ) )
			{
				$person->set_value( 'name', $name->{name} );
				last;
			}
		}
	}
	else
	{
		$person->set_value( 'name', undef );
	}

},  id => 'update_id_fields', priority => 100 );


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
