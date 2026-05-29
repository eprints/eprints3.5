
$c->{set_eprint_automatic_fields} = sub
{
	my( $eprint ) = @_;

 	# This is a handy place to set default
    #unless( $eprint->is_set( "institution" ) )
    #{
    #    $eprint->set_value( "institution", "University of Southampton" );
    #}
	
#	my @docs = $eprint->get_all_documents();
#	my $textstatus = "none";
#	if( scalar @docs > 0 )
#	{
#		$textstatus = "public";
#		foreach my $doc ( @docs )
#		{
#			if( !$doc->is_public )
#			{
#				$textstatus = "restricted";
#				last;
#			}
#		}
#	}
#	$eprint->set_value( "full_text_status", $textstatus );
};


=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
