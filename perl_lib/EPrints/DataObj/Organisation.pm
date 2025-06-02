######################################################################
#
# EPrints::DataObj::Organisation
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::DataObj::Organisation> - A data object that represents a organisation.

=head1 DESCRIPTION

UNDER DEVELOPMENT

Designed to extend L<EPrints::DataObj::Entity> to represent a organisation.

=head1 CORE METADATA FIELDS

None.

=head1 REFERENCES AND RELATED OBJECTS

None.

=head1 INSTANCE VARIABLES

See L<EPrints::DataObj::Entity|EPrints::DataObj::Entity#INSTANCE_VARIABLES>.

=head1 METHODS

=cut
######################################################################

package EPrints::DataObj::Organisation;

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

=item $dataset = EPrints::DataObj::Organisation->get_dataset_id

Returns the ID of the L<EPrints::DataSet> object to which this record
belongs.

=cut
######################################################################

sub get_dataset_id { "organisation" }


######################################################################
=pod

=item $system_field_info = EPrints::DataObj::Organisation->get_system_field_info

Returns an array describing the system metadata of the organisation dataset.

=cut
######################################################################

sub get_system_field_info
{
	my( $class ) = @_;

	return (
	{ 
		name=>"orgid", 
		type=>"counter", 
		required=>1, 
		import=>0, 
		can_clone=>0,
		sql_counter=>"orgid" 
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
	},

	{
		name => 'name',
		type => 'text',
		input_cols => 30,
	},

	{
		name => 'names',
		type => 'multilang',
		fields=>[
			{
				sub_name => 'name',
			type => 'text',
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
	},

	{
		name=>"lastmod", 
		type=>"timestamp", 
		required=>0, 
		import=>0,
		render_res=>"minute", 
		render_style=>"short", 
		can_clone=>0, 
		volatile=>1 
	},

  	);
}


######################################################################
=cut

=back

=head2 Object Methods

=cut
######################################################################


1;


######################################################################
=pod

=back

=head1 SEE ALSO

L<EPrints::DataObj> and L<EPrints::DataSet>.

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

