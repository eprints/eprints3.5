=head1 NAME

EPrints::Plugin::Issues::XMLConfig

=cut

package EPrints::Plugin::Issues::XMLConfig;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Issues" );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{name} = "Issues XML Config File";

	return $self;
}

sub config_file
{
	my( $plugin ) = @_;

	return $plugin->{session}->get_repository->get_conf( "config_path" )."/issues.xml";
}

sub get_config
{
	my( $plugin ) = @_;

	if( !defined $plugin->{issuesconfig} )
	{
		my $file = $plugin->config_file;
		my $doc = $plugin->{session}->get_repository->parse_xml( $file , 1 );
		if( !defined $doc )
		{
			$plugin->{session}->get_repository->log( "Error parsing $file\n" );
			return;
		}
	
		$plugin->{issuesconfig} = ($doc->getElementsByTagName( "issues" ))[0];
		if( !defined $plugin->{issuesconfig} )
		{
			$plugin->{session}->get_repository->log(  "Missing <issues> tag in $file\n" );
			EPrints::XML::dispose( $doc );
			return;
		}
	}
	
	return $plugin->{issuesconfig};
}

sub is_available
{
	my( $plugin ) = @_;

	return( -e $plugin->config_file );
}

# return an array of issues. Issues should be of the type
# { description=>XHTML String, type=>string }
# if one item can have multiple occurrences of the same issue type then add
# an id field too. This only need to be unique within the item.
sub item_issues
{
	my( $plugin, $dataobj ) = @_;
	
	my %params = ();
	$params{item} = $dataobj;
	$params{current_user} = $plugin->{session}->current_user;
	$params{session} = $plugin->{session};
	my $issues = EPrints::XML::EPC::process( $plugin->get_config, %params );

	my @issues_list = ();
	foreach my $child ( $issues->getChildNodes )
	{
		next unless( $child->nodeName eq "issue" );
		my $issue = {};
		$issue->{description} = EPrints::XML::contents_of( $child );
		$issue->{type} = $child->getAttribute( "type" );
		$issue->{id} = $child->getAttribute( "issue_id" );
		push @issues_list, $issue;
	}

	return @issues_list;
}

1;



=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
