package EPrints::Plugin::Export::BundleUser;

use EPrints::Plugin::Export::Bundle;
@ISA = ( "EPrints::Plugin::Export::Bundle" );

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Bundle";
	$self->{accept} = [ 'list/eprint' ];
	$self->{visible} = "all";
	$self->{advertise} = 1;
	$self->{export_name} = "bundle";
	$self->{extras} = [ 'DC', 'EndNote' ];
	$self->{max} = 20;
	$self->{max_filesize} = 100 * 1024 * 1024;
	
	return $self;
}

1;
