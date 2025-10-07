

######################################################################
#
# EP_TRIGGER_WARNINGS 'eprint' dataset trigger
#
######################################################################
#
# $dataobj
# - EPrint object
# $repository
# - Repository object (the current repository)
# $for_archive
# - Is this being checked to go live (`1` means it is)
# $warnings
# - ARRAYREF of DOM objects
#
######################################################################
#
# Create warnings which will appear on the final deposit page but
# will not actually prevent the item being deposited.
#
# Any span tags with a class of ep_problem_field:fieldname will be
# linked to fieldname in the workflow.
#
######################################################################

$c->add_dataset_trigger( 'eprint', EPrints::Const::EP_TRIGGER_WARNINGS, sub {
	my( %args ) = @_;
	my( $repository, $eprint, $warnings ) = @args{qw( repository dataobj warnings )};

	my @docs = $eprint->get_all_documents;
	if( @docs == 0 )
	{
		push @$warnings, $repository->html_phrase( "warnings:no_documents" );
	}
}, id => 'no_documents' );

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

