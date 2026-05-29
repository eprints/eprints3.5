######################################################################
#
# EPrints::DataObj::Person
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Person> - A data object that represents a person.

=head1 DESCRIPTION

UNDER DEVELOPMENT

Designed to extend L<EPrints::DataObj::Entity> to represent a person.

=head1 CORE METADATA FIELDS

None.

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj::Entity|EPrints::DataObj::Entity#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Person;

@ISA = ( 'EPrints::DataObj::Entity' );

use strict;

######################################################################
=pod

=head2 Class Methods

=cut
######################################################################

######################################################################
=pod

=over 4

=item $dataset = EPrints::DataObj::Person->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id { "person" }


######################################################################
=pod

=item $system_field_info = EPrints::DataObj::Person->get_system_field_info

Returns an array describing the system metadata of the person dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return (
	{
		name=>"personid",
		type=>"counter",
		required=>1,
		import=>0,
		can_clone=>0,
		sql_counter=>"personid",
	},

	{
		name => 'id_value',
		type => 'id',
	},

	{
		name => 'id_type',
		type => 'namedset',
		set_name => $class->get_dataset_id . "_id_type",
	},


	{
		name => 'ids',
		type => 'compound',
		multiple => 1,
		fields => [
			{
				sub_name => 'id',
				type => 'id',
			},
			{
				sub_name => 'id_type',
				type => 'namedset',
				set_name => $class->get_dataset_id . "_id_type",
			},
		],
		input_boxes => 1,
		required => 1,
		render_value => 'render_entity_ids',
	},

	{
		name => 'name',
		type => 'name',
		input_cols => 30,
	},

	{
		name => 'names',
		type => 'compound',
		fields=>[
			{
				sub_name => 'name',
				type => 'name',
				input_cols => 30,
				required => 1,
			},
			{
				sub_name => 'from',
				type => 'date',
			},
			{
				sub_name => 'to',
				type => 'date',
			},
		],
		multiple => 1,
		input_boxes => 1,
		render_value => 'render_entity_names',
	},

	{
		name=>"lastmod",
		type=>"timestamp",
		required=>0,
		import=>0,
		render_res=>"minute",
		render_style=>"short",
		can_clone=>0,
		volatile=>1,
	},

  	);
}


######################################################################
=cut

=back

=head2 Object Methods

=cut
######################################################################

######################################################################
=pod

=item $serialised_name = EPrints::DataObj::Person->serialise_name( $name )

Returns serialisation of person's C<$name> to make it quicker to
compare.

=cut
######################################################################

sub serialise_name
{
	my( $class, $name ) = @_;

	my $serialised_name = $name->{given} . " " . $name->{family};
	$serialised_name =~ s/^\s+|\s+$//g;
	$serialised_name = $name->{honourfic} . " " . $serialised_name if $name->{honourfic};
	$serialised_name .= " " . $name->{lineage} if $name->{lineage};

	return $serialised_name;
}


1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
