######################################################################
#
# EP_TRIGGER_VALIDATE 'user' dataset trigger
#
######################################################################
#
# $dataobj 
# - User object
# $repository 
# - Repository object (the current repository)
# $for_archive
# - Is this being checked to go live (`1` means it is)
# $problems
# - ARRAYREF of DOM objects
#
######################################################################
#
# Validate a user, although all the fields will already have been
# checked with validate_field so only complex problems need to be
# tested.
#
######################################################################

#$c->add_dataset_trigger( 'user', EPrints::Const::EP_TRIGGER_VALIDATE, sub {
#	my( %args ) = @_;
#	my( $repository, $user, $for_archive, $problems ) = @args{qw( repository dataobj for_archive problems )};
#
#	push @$problems, $repository->make_text( 'Demo user validation trigger' );
#}, id => 'demo_id' );

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
