######################################################################
#
#  Maximum size of a file that can be uploaded to an EPrints archive
#
######################################################################
#
#  Used by generate_apacheconf and 99_uploadmethod_file_max_size.js.
#  Limits maximum size of a file that can be upload to an archive.
######################################################################

$c->{max_upload_filesize} = 1 * 1024 * 1024 * 1024; # 1 GiB

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
