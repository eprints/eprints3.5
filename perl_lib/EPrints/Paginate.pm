######################################################################
#
# EPrints::Paginate
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Paginate> - Methods for rendering a paginated List

=head1 DESCRIPTION

=over 4

=cut

######################################################################
package EPrints::Paginate;

use URI::Escape;
use strict;

######################################################################
=pod

=item $xhtml = EPrints::Paginate->paginate_list( $session, $basename, $list, %opts )

Render a "paginated" view of the list i.e. display a "page" of items 
with links to navigate through the list.

$basename is the basename to use for pagination-specific CGI parameters, to avoid clashes.

%opts is a hash of options which can be used to customise the 
behaviour and/or rendering of the paginated list. See EPrints::Search 
for a good example!

B<Behaviour options:>

=over 4

=item page_size	

The maximum number of items to display on a page.

=item pagejumps

The maximum number of page jump links to display.

=item params

A hashref of parameters to include in the prev/next/jump URLs, 
e.g. to maintain the state of other controls on the page between jumps.

=back

B<Rendering options:>

=over 4

=item controls_before, controls_after

Additional links to display before/after the page navigation controls.

=item container

A containing XML DOM element for the list of items on the current page.

=item render_result, render_result_params

A custom subroutine for rendering an individual item on the current 
page. The subroutine will be called with $session, $item, and the
parameter specified by the render_result_params option. The
rendered item should be returned.

=item phrase

The phrase to use to render the entire "page". Can make use of the following pins:

=over 4

=item controls

prev/next/jump links

=item searchdesc

description of list e.g. what search parameters produced it

=item matches

total number of items in list, range of items displayed on current page

=item results

list of rendered items

=item controls_if_matches

prev/next/jump links (only if list contains >0 items)

=back

These can be overridden in the "pins" option (below).

=item pins

Named "pins" to render on the page. These may override the default 
"pins" (see above), or specify new "pins" (although you would need 
to define a custom phrase in order to make use of them).

=back

=cut
######################################################################

sub paginate_list
{
	my( $class, $session, $basename, $list, %opts ) = @_;

	my $n_results = $list->count();
	my $offset = defined $opts{offset} ? $opts{offset} : ($session->param( $basename."_offset" ) || 0);
	$offset += 0;
	my $pagesize = defined $opts{page_size} ? $opts{page_size} : ($session->param( $basename."page_size" ) || 10); # TODO: get default from somewhere?
	$pagesize += 0;
	my @results = $list->get_records( $offset , $pagesize );
	my $plast = $offset + $pagesize;
	$plast = $n_results if $n_results< $plast;

	# Add params to action urls
	my $url = URI->new( $session->get_uri );
	my @param_list;
	#push @param_list, "_cache=" . $list->get_cache_id; # if cached
	#my $escexp = $list->{encoded}; # serialised search expression
	#$escexp =~ s/ /+/g; # not great way...
	#push @param_list, "_exp=$escexp";
	if( defined $opts{params} )
	{
		my $params = $opts{params};
		foreach my $key ( keys %$params )
		{
			my $value = $params->{$key};
			push @param_list, $key => $value if defined $value;
		}
	}
	$url->query_form( @param_list );

	my $paginate_data = {
		url => $url,
		basename => $basename,
		from => $offset + 1,
		to => $plast,
		n_results => $n_results,
		page_size => $opts{page_size},
	};

	my $results_info = {
		n_results => $n_results,
		rows_before => $opts{rows_before},
		rows => [],
		rows_after => $opts{rows_after},
	};

	if( scalar $n_results > 0 )
	{
		if( !$opts{page_size} )
		{
			if( defined $session->param( "${basename}page_size" ) )
			{
				$url->query_form( @param_list, $basename."page_size" => $pagesize );
			}
		}
	}

	my @controls; # page controls

	if( defined $opts{controls_before} )
	{
		foreach my $control ( @{ $opts{controls_before} } )
		{
   			push @controls, { url => $control->{url}, label => $control->{label}, type => 'before' };
		}
	}

	# Previous page link
	if( $offset > 0 ) 
	{
		my $bk = $offset-$pagesize;
		my $prevurl = "$url&$basename\_offset=".($bk<0?0:$bk);

		push @controls, { url => $prevurl, type => 'previous' };
	}

	# Page jumps
	my $pages_to_show = $opts{pagejumps} || 10; # TODO: get default from somewhere?
	my $cur_page = $offset / $pagesize;
	my $num_pages = int( $n_results / $pagesize );
	$num_pages++ if $n_results % $pagesize;
	$num_pages--; # zero based

	my $start_page = $cur_page - ( $pages_to_show / 2 );
	my $end_page = $cur_page + ( $pages_to_show / 2 );

	if( $start_page < 0 )
	{
		$end_page += -$start_page; # end page takes up slack
	}
	if( $end_page > $num_pages )
	{
		$start_page -= $end_page - $num_pages; # start page takes up slack
	}

	$start_page = 0 if $start_page < 0; # normalise
	$end_page = $num_pages if $end_page > $num_pages; # normalise
	unless( $start_page == $end_page ) # only one page, don't need jumps
	{
		for my $page_n ( $start_page..$end_page )
		{
			my $jumpurl = "$url&$basename\_offset=" . $page_n * $pagesize;

			push @controls, { url => $jumpurl, label => $page_n + 1,
				type => $page_n != $cur_page ? "jump" : "current" };
		}
	}

	# Next page link
	if( $offset + $pagesize < $n_results )
	{
		my $nexturl="$url&$basename\_offset=".($offset+$pagesize);

		push @controls, { url => $nexturl, type => 'next' };
	}

	my $has_main_controls = scalar @controls > 0;

	my $type;

	if( !defined $opts{container} )
	{
		$type = $session->get_citation_type( $list->get_dataset );
	}

	my $n = $offset;
	foreach my $result ( @results )
	{
		$n += 1;

		my $row_info = {
			index => $n,
			as_div => 0,
		};

		# Render individual results
		if( defined $opts{render_result} )
		{
			# Custom rendering routine specified

			$row_info->{render} = &{ $opts{render_result} }(
						$session,
						$result,
						$opts{render_result_params},
						$n );
		}
		elsif( $type eq "table_row" )
		{
			$row_info->{render} = $result->render_citation_link();
		}
		else
		{
			$row_info->{as_div} = 1;
			$row_info->{render} = $result->render_citation_link();
		}

		push $results_info->{rows}, $row_info;
	}

	# If we have no results, we can use a custom renderer to	
	# put a descriptive phrase in place of the result list.

	if( $n_results == 0 )
	{
		if( defined $opts{render_no_results} )
		{
			my $params = $opts{render_result_params};

			$results_info->{no_results_message} = &{ $opts{render_no_results} }(
					$session,
					$params,
					$session->html_phrase( 
						"lib/paginate:no_items" )
					);
		}
	}

	my %pins;

	$pins{above_results} = $opts{above_results};

	if( !defined $pins{above_results} )
	{
		$pins{above_results} = $session->make_doc_fragment;
	}

	$pins{below_results} = $opts{below_results};

	if( !defined $pins{below_results} )
	{
		$pins{below_results} = $session->make_doc_fragment;
	}

	$results_info->{container} = $opts{container};
	$results_info->{citation_type} = $type;

	$pins{results} = $session->template_phrase( "view:EPrints/Paginate:paginate_list/results_container", { item => $results_info } );

	$paginate_data->{control_links} = \@controls;
	$paginate_data->{controls_after} = $opts{controls_after};
	$paginate_data->{has_main_controls} = $has_main_controls;

	if( $has_main_controls || $opts{controls_after} )
	{
		$pins{controls} = $session->template_phrase( "view:EPrints/Paginate:paginate_list/controls", { item => $paginate_data } );
	}

	# Apply custom pins.

	my $custom_pins = $opts{pins};

	for( keys %$custom_pins )
	{
		$pins{$_} = $custom_pins->{$_} if defined $custom_pins->{$_};
	}

	$paginate_data->{above_results} = $pins{above_results};
	$paginate_data->{below_results} = $pins{below_results};
	$paginate_data->{results} = $pins{results};
	$paginate_data->{controls} = $pins{controls};

	return $session->template_phrase( "view:EPrints/Paginate:paginate_list", { item => $paginate_data } );
}

1;

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

