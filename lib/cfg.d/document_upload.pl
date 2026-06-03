
######################################################################
#
#  Document file upload information
#
######################################################################

# This sets the minimum amount of free space allowed on a disk before EPrints
# starts using the next available disk to store EPrints. Specified in kilobytes.
$c->{diskspace_error_threshold} = 64*1024;

# If ever the amount of free space drops below this threshold, the
# repository administrator is sent a warning email. In kilobytes.
$c->{diskspace_warn_threshold} = 512*1024;

# Add an additional MIME type mapping from file extensions
# $c->{mimemap}->{html} = "text/html";

# Limit maximum files that can be expanded from an archive (e.g. zip file)
# $c->{archive_max_files} = 100;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
