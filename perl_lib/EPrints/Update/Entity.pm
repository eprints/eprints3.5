######################################################################
#
# EPrints::Update::Entity
#
######################################################################
#
#
######################################################################


=pod

=head1 NAME

B<EPrints::Update::Entity>

=head1 DESCRIPTION

Update entity summary web pages on demand.

=over 4

=cut

package EPrints::Update::Entity;

use Data::Dumper;

use strict;
  
sub update
{
	my( $repository, $lang, $datasetid, $entity_id, $uri ) = @_;

	my $localpath = sprintf("%08d", $entity_id );
	$localpath =~ s/(..)/\/$1/g;
	$localpath = "/$datasetid" . $localpath . "/index.html";

	my $targetfile = $repository->get_conf( "htdocs_path" )."/".$lang.$localpath;

	my $need_to_update = 0;

	if( !-e $targetfile ) 
	{
		$need_to_update = 1;
	}

	my $timestampfile = $repository->get_conf( "variables_path" )."/entities.timestamp";	
	if( -e $timestampfile && -e $targetfile )
	{
		my $poketime = (stat( $timestampfile ))[9];
		my $targettime = (stat( $targetfile ))[9];
		if( $targettime < $poketime ) { $need_to_update = 1; }
	}

	return unless $need_to_update;

	# There is an entities file, AND we're looking
	# at serving an entity page, AND the entities timestamp
	# file is newer than the entities page...
	# so try and regenerate the entities page.

	my $dataset = $repository->dataset( $datasetid );
	my $entity = $dataset->dataobj( $entity_id );
	return unless defined $entity;

	$entity->generate_static;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
