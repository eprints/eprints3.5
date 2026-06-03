

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

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
