
# This is a simple demo to show how to add code to redirect certain URLs,
# or to do more clever stuff too.

# EPrints will stop working through the triggers if EP_TRIGGER_DONE is 
#   returned.
# EPrints will stop processing the request if the $o{return_code} is set at 
#   the end of the triggers.

# $c->add_trigger( EP_TRIGGER_URL_REWRITE, sub {
#	my( %o ) = @_;
#
#	if( $o{uri} eq $o{urlpath}."/testpath" )
#	{
#		${$o{return_code}} = EPrints::Apache::Rewrite::redir( $o{request}, "http://totl.net/" );
#		return EP_TRIGGER_DONE;
#	}
# }, id => 'testpath_to_totl', priority => 100 );


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
