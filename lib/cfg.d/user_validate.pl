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

