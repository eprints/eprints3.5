=head1 NAME

EPrints::Plugin::Export::Subject

=cut

package EPrints::Plugin::Export::Subject;

use EPrints::Plugin::Export;

@ISA = ( "EPrints::Plugin::Export" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Subjects file";
	$self->{accept} = [ 'dataobj/subject', 'list/subject' ];
	$self->{visible} = "all";
	$self->{suffix} = ".txt";
	$self->{mimetype} = "text/plain; charset=utf-8";
	
	return $self;
}

sub output_dataobj
{
	my( $self, $dataobj ) = @_;

	my @parts;

	push @parts, $dataobj->get_id;
	my $names = $dataobj->get_value( "name_name" );
	if( EPrints::Utils::is_set( $names ) )
	{
		push @parts, $names->[0];
	}
	else
	{
		push @parts, "";
	}
	my $parents = $dataobj->get_value( "parents" );
	push @parts, join ",", @$parents;
	push @parts, $dataobj->is_set( "depositable" ) && $dataobj->get_value( "depositable" ) eq "TRUE" ? "1" : "0";

	# percent-encode ":" to "%3A"
	foreach my $i (0..$#parts)
	{
		$parts[$i] =~ s/:/%3A/g;	
	}

	return join(":", @parts)."\n";
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
