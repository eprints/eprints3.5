######################################################################
#
# EPrints::Init
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Init> - Initialisation functions

=head1 DESCRIPTION

=head1 METHODS

=cut

package EPrints::Init;

use warnings;
use strict;

use YAML::Tiny;

######################################################################
=pod

=item $load_order = EPrints::Init::get_load_order( $base_path, [ $archiveroot ] )

Determines the load order of libraries.

Takes the C<$base_path> for EPrints and optionally the C<$archiveroot>
path for a partiucular repository archive.

Returns an array reference with paths for the loading order of 
libraries. Ideally for the repository archive or generically for the 
repository.

=cut
######################################################################

sub get_load_order
{
        my ( $base_path, $archiveroot, $test ) = @_;

        my $includes = get_includes( get_package_config( $base_path, $archiveroot, $test ) );

        my $load_order = [ $base_path . "/lib" ];

        foreach my $inc ( @{ $includes } )
        {
                push @$load_order, $base_path . "/" . $inc;
        }
        push @$load_order, $archiveroot if defined $archiveroot;

        return $load_order;
}


######################################################################
=pod

=item $pkg_cfg = EPrints::Init::get_package_config( $base_path, [ $archiveroot ] )

Load information from appropriate B<package.yml> YAML file.

Takes the C<$base_path> for EPrints and optionally the C<$archiveroot>
path for a particular repository archive.

Returns a hash reference containing the package configuration loaded 
from the YAML file.

=cut
######################################################################

sub get_package_config
{
	my ( $base_path, $archiveroot, $test ) = @_;

	my $pkg_cfg;
	my $repoid;

	if ( $archiveroot )
	{
		my @arbits = split( '/', $archiveroot );
		$repoid = $arbits[$#arbits];
		my $pkg_filepath = $archiveroot . "/cfg/package.yml";

		if ( ! -f $pkg_filepath )
		{
			print STDERR "ERROR: No file at: $pkg_filepath\n\n";
			exit 1;
		}

		my $yaml = YAML::Tiny->read( $pkg_filepath );
		if ( !defined $yaml || !defined $yaml->[0] )
		{
			print STDERR "ERROR: Could not read YAML in $pkg_filepath file\n\n";
			exit 1;
		}

		$pkg_cfg = $yaml->[0];
		if ( !defined $pkg_cfg->{id} || !defined $pkg_cfg->{name} || !defined $pkg_cfg->{includes} || !defined $pkg_cfg->{includes}->[0] )
		{
			print STDERR "ERROR Invalid package file at: $pkg_filepath\n\n";
			exit 1;
		}
	}
	else
	{
		my $conf = $EPrints::SystemSettings::conf;
		$pkg_cfg->{includes} = defined $conf->{includes} ? $conf->{includes} : [];
	}

	return $pkg_cfg unless $test;

	my %includes = ();
	my $core_version = EPrints->VERSION =~ /^v/ ? substr(  EPrints->VERSION, 1 ) : join( '.', map { ord($_) } split( //,  EPrints->VERSION ) ) ;
	my %inccomps = ( core => $core_version );
	my @reqs = ();

	foreach ( @{$pkg_cfg->{includes}} )
	{
		$includes{$_->{path}} = $_->{version};
	}

	foreach my $comp ( keys %includes )
	{
		my $comp_filepath = $base_path . '/' . $comp . '/' . 'component.yml';
		unless ( -f $comp_filepath )
		{
			print STDERR "WARNING: No component.yml for path: $comp\n";
			next;
		}
		my $cyaml = YAML::Tiny->read( $comp_filepath );
		if ( !defined $cyaml || !defined $cyaml->[0] )
		{
			print STDERR "WARNING: Could not read YAML at: $comp_filepath\n";
			next;
		}
		my $comp_cfg = $cyaml->[0];
		if ( !defined $comp_cfg->{id} || !defined $comp_cfg->{name} || !defined $comp_cfg->{type} || !defined $comp_cfg->{version} )
		{
			print STDERR "WARNING: Invalid component file at: $comp_filepath\n";
			next;
		}
		my ( $compare, $version ) = split( ' ', $includes{$comp} );
		if ( !$version )
		{
			$version = $compare;
			$compare = '=';
		}
		my $version_ok = EPrints::Utils::compare_version( $compare, $version, $comp_cfg->{version} );
		unless ( $version_ok )
		{
			print STDERR "WARNING: Archive '$repoid' requires " . $includes{$comp} . " version $compare $version (got " . $comp_cfg->{version} . ").\n";
		}
		$inccomps{$comp_cfg->{id}} = $comp_cfg->{version};
		if ( defined $comp_cfg->{requires} && defined $comp_cfg->{requires}->[0] )
		{
			foreach my $req ( @{$comp_cfg->{requires}} )
			{
				$req->{requirer} = $comp_cfg->{id};
				push @reqs, $req;
			}
		}
	}

	foreach my $req ( @reqs )
	{
		unless ( $inccomps{$req->{component}} )
		{
			print STDERR "WARNING: Archive '$repoid' includes component '" . $req->{requirer} . "' that requires missing component '" . $req->{component} . "'.\n";
			next;
		}
		my ( $compare, $version ) = split( ' ', $req->{version} );
		if ( !$version )
		{
			$version = $compare;
			$compare = '=';
		}
		my $version_ok = EPrints::Utils::compare_version( $compare, $version, $inccomps{$req->{component}} );
		unless ( $version_ok )
		{
			print STDERR "WARNING: Archive '$repoid' includes component '" . $req->{requirer} ."' that requires '" . $req->{component} . "' version $compare $version (got " . $inccomps{$req->{component}} . ").\n";
		}
	}

	return $pkg_cfg;
}

######################################################################
=pod

=item $lib_paths = EPrints::Init::get_includes( $pkg_cfg )

Just get the includes paths from a package configuration.

Takes a C<$pkg_cfg> package configuration hash reference.

Returns an array reference of the includes paths defined in the 
package configuration.

=cut
######################################################################


sub get_includes
{
        my ( $pkg_cfg ) = @_;
	
	my @includes = ();
	foreach my $include ( @{ $pkg_cfg->{includes} } )
	{
		push @includes, $include->{path};
	}
	return \@includes;
}


######################################################################
=pod

=item $lib_paths = EPrints::Init::get_lib_paths( $base_path, $sub_path )

Generate the library paths for a specific type of code or 
configuration files.

Takes the C<$base_path> for EPrints and the C<$sub_path> specifying
sub-directory path to follow under the library path.

Returns an array containing the full paths for a specific type of code 
or configuration files.

=cut
######################################################################

sub get_lib_paths
{
        my ( $load_order, $sub_path ) = @_;

        my @lib_paths = ();
        foreach my $lo ( @$load_order )
        {
                if ( $lo =~ m!/archives/! && $sub_path ne "cgi" )
                {
                        push @lib_paths, $lo . "/cfg/$sub_path";
                }
                else
                {
                        push @lib_paths, $lo . "/$sub_path";
                }
        }

        return @lib_paths;
}


######################################################################
=pod

=item EPrints::Init::update_inc_paths( $load_order, $base_path )

Update the library paths within EPrints that used in the include paths 

Takes the array reference C<$load_order> of library paths and the
C<$base_path> for EPrints to updat the includes path (i.e C<@INC> )

=cut
######################################################################

sub update_inc_paths
{
	my ( $load_order, $base_path ) = @_;

	my @new_inc = ();
	foreach ( @INC )
	{
		push @new_inc, $_ unless $_ =~ m!^$base_path!;
	}

	unshift @new_inc, ( $base_path . "/perl_lib" );
	unshift @new_inc, reverse @$load_order;

	@INC = @new_inc;
}


1;


######################################################################

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.5 is supplied by EPrints Services.

https://www.eprints.org/eprints-3.5/

=end COPYRIGHT

=begin LICENSE

This file is part of EPrints 3.5 L<https://www.eprints.org/>.

EPrints 3.5 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.5 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.5.
If not, see L<https://www.gnu.org/licenses/>.

=end LICENSE

