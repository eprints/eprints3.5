package EPrints::Plugin::Export::BundleStaff;

use EPrints::Plugin::Export::Bundle;
@ISA = ( "EPrints::Plugin::Export::Bundle" );

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "Bundle (Staff)";
	$self->{accept} = [ 'list/eprint' ];
	$self->{visible} = "staff";
	$self->{advertise} = 1;
	$self->{export_name} = "bundle";
	$self->{extras} = [ 'DC', 'EndNote', 'XML', 'JSON', 'MultilineCSV' ];

	$self->{max} = 100;
	$self->{hard_max} = 200;
	$self->{max_filesize} = 200 * 1024 * 1024;

	return $self;
}

1;
