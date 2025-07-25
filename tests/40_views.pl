use strict;
use Test::More tests => 6;

BEGIN { use_ok( "EPrints" ); }
BEGIN { use_ok( "EPrints::Test" ); }


$SIG{INT} = sub { die "CAUGHT SIGINT\n" };

EPrints::Test::mem_increase();

my $repo = EPrints::Test->repository;

$repo->cache_subjects;

my $views = $repo->config( "browse_views" );

my $ds = $repo->dataset( "archive" );

my $test_id = "_40_views_pl";

my $lang = $repo->get_lang;
my $langid = $lang->{id};

my $viewdir = File::Temp->newdir();

local $repo->{config}->{htdocs_path} = "$viewdir";

# Work-around to suppress the phrase warnings
{
my $data = $lang->_get_repositorydata;
my $phrase = $repo->make_element( "phrase", id => "viewname_eprint_$test_id" );
$phrase->appendChild( $repo->make_text( $test_id ) );
$data->{xml}->{"viewname_eprint_$test_id"} = $phrase;
keys %{$data->{file}};
(undef, $data->{file}->{"viewname_eprint_$test_id"}) = each %{$data->{file}};
keys %{$data->{file}};
}

my $test_view = 
{
	id => $test_id,
	allow_null => 1,
	fields => "-date;res=year",
	order => "creators_name/title",
	variations => [
		"creators_name;first_letter",
		"type",
		"DEFAULT" ],
};

my $view = EPrints::Update::Views->new(
	repository => $repo,
	view => $test_view
);

EPrints::Test::mem_increase();
Test::More::diag( "memory footprint\n" );

$view->update_view_by_path(
		on_write => sub { diag( $_[0] ); },
		langid => $langid, 
		do_menus => 1,
		do_lists => 1 );

ok( -e "$viewdir/$langid/view/$test_id/index.page", "browse_view_menu");
ok( -e "$viewdir/$langid/view/$test_id/2022.page", "browse_view_menu");

Test::More::diag( "\t update_view_by_path=" . EPrints::Test::human_mem_increase() );

EPrints::Update::Views::update_view_file(
		$repo,
		$langid,
		"view/index.html" );

ok( -e "$viewdir/$langid/view/index.page", "browse_view_menu");

Test::More::diag( "\t update_browse_view_list=" . EPrints::Test::human_mem_increase() );

ok(1);



=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2022 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=for COPYRIGHT END

=for LICENSE BEGIN

This file is part of EPrints 3.4 L<http://www.eprints.org/>.

EPrints 3.4 and this file are released under the terms of the
GNU Lesser General Public License version 3 as published by
the Free Software Foundation unless otherwise stated.

EPrints 3.4 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with EPrints 3.4.
If not, see L<http://www.gnu.org/licenses/>.

=for LICENSE END

