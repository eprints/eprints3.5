
# Enable edit locking, which will prevent users modifying records
# while other users are working on them.

$c->{locking}->{eprint}->{enable} = 1;

$c->{locking}->{eprint}->{timeout} = 3600;


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
