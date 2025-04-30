=head1 NAME

EPrints::Plugin::Screen::Search

=cut

package EPrints::Plugin::Screen::Search;

use EPrints::Plugin::Screen::AbstractSearch;
@ISA = ( 'EPrints::Plugin::Screen::AbstractSearch' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [];
	push @{$self->{actions}}, "advanced", "savesearch";

	return $self;
}

sub datasets
{
	my( $self ) = @_;

	my $session = $self->{session};

	my @datasets;

	foreach my $datasetid ($session->get_dataset_ids)
	{
		local $self->{processor}->{dataset} = $session->dataset( $datasetid );
		next if !$self->can_be_viewed();
		push @datasets, $datasetid;
	}

	return @datasets;
}

sub search_dataset
{
	my( $self ) = @_;

	return $self->{processor}->{dataset};
}

sub allow_advanced { shift->can_be_viewed( @_ ) }
sub allow_export { shift->can_be_viewed( @_ ) }
sub allow_export_redir { shift->can_be_viewed( @_ ) }
sub allow_savesearch
{
	my( $self ) = @_;

	return 0 if !$self->can_be_viewed();

	my $user = $self->{session}->current_user;
	return defined $user && $user->allow( "create_saved_search" );
}
sub can_be_viewed
{
	my( $self ) = @_;

	# note this method is also used by $self->datasets()

	my $dataset = $self->{processor}->{dataset};
	return 0 if !defined $dataset;

	my $searchid = $self->{processor}->{searchid};

	if( $dataset->id eq "archive" )
	{
		return $self->allow( "eprint_search" );
	}
	elsif( defined($searchid) && (my $rc = $self->allow( $dataset->id . "/search/$searchid" )) )
	{
		return $rc;
	}
	{
		return $self->allow( $dataset->id . "/search" );
	}
}

sub get_controls_before
{
	my( $self ) = @_;

	my @controls = $self->get_basic_controls_before;

	my $cacheid = $self->{processor}->{results}->{cache_id};
	my $escexp = $self->{processor}->{search}->serialise;

	my $baseurl = URI->new( $self->{session}->get_uri );
	$baseurl->query_form(
		cache => $cacheid,
		exp => $escexp,
		screen => $self->{processor}->{screenid},
		dataset => $self->search_dataset->id,
		order => $self->{processor}->{search}->{custom_order},
	);

# Maybe add links to the pagination controls to switch between simple/advanced
#	if( $self->{processor}->{searchid} eq "simple" )
#	{
#		push @controls, {
#			url => "advanced",
#			label => $self->{session}->html_phrase( "lib/searchexpression:advanced_link" ),
#		};
#	}

	my $user = $self->{session}->current_user;
	if( defined $user && $user->allow( "create_saved_search" ) )
	{
		#my $cacheid = $self->{processor}->{results}->{cache_id};
		#my $exp = $self->{processor}->{search}->serialise;

		my $url = $baseurl->clone;
		$url->query_form(
			$url->query_form,
			_action_savesearch => 1
		);

		push @controls, {
			url => "$url",
			label => $self->{session}->html_phrase( "lib/searchexpression:savesearch" ),
		};
	}

	return @controls;
}

sub hidden_bits
{
	my( $self ) = @_;

	my %bits = $self->SUPER::hidden_bits;

	my @datasets = $self->datasets;

	# if there's more than 1 dataset, then the search form will render the list of "search-able" datasets - see render_dataset below
	if( scalar( @datasets ) < 2 )
	{
		$bits{dataset} = $self->{processor}->{dataset}->id;
	}

	return %bits;
}

sub render_result_row
{
	my( $self, $session, $result, $searchexp, $n ) = @_;

	my $staff = $self->{processor}->{sconf}->{staff};
	my $citation = $self->{processor}->{sconf}->{citation};

	#if we have a template, add it on the end of the item's url
	my %params;
	if( defined $self->{processor}->{sconf}->{template} )
	{
		$params{url} = $result->url . "?template=" . $self->{processor}->{sconf}->{template};
        }

	$params{n} = [$n,"INTEGER"];

	if( $staff )
	{
		return $result->render_citation_link_staff( $citation,
			%params );
	}
	else
	{
		return $result->render_citation_link( $citation,
			%params );
	}
}

sub export_url
{
	my( $self, $format ) = @_;

	my $plugin = $self->{session}->plugin( "Export::".$format );
	if( !defined $plugin )
	{
		EPrints::abort( "No such plugin: $format\n" );
	}

	my $url = URI->new( $self->{session}->current_url() . "/export_" . $self->{session}->get_repository->get_id . "_" . $format . $plugin->param( "suffix" ) );

	$url->query_form(
		$self->hidden_bits,
		_action_export => 1,
		output => $format,
		exp => $self->{processor}->{search}->serialise,
		n => scalar($self->{session}->param( "n" )),
	);

	return $url;
}

sub action_advanced
{
	my( $self ) = @_;

	my $adv_url;
	my $datasetid = $self->{session}->param( "dataset" );
	$datasetid = "archive" if !defined $datasetid; # something odd happened
	if( $datasetid eq "archive" )
	{
		$adv_url = $self->{session}->current_url( path => "cgi", "search/advanced" );
	}
	else
	{
		$adv_url = $self->{session}->current_url( path => "cgi", "search/$datasetid/advanced" );
	}

	$self->{processor}->{redirect} = $adv_url;
}

sub action_savesearch
{
	my( $self ) = @_;

	my $ds = $self->{session}->dataset( "saved_search" );

	my $searchexp = $self->{processor}->{search};
	$searchexp->{searchid} = $self->{processor}->{searchid};

	my $name = $searchexp->render_conditions_description;
	my $userid = $self->{session}->current_user->id;

	my $spec = $searchexp->freeze;
	my $results = $ds->search(
		filters => [
			{ meta_fields => [qw( userid )], value => $userid, },
			{ meta_fields => [qw( spec )], value => $spec, match => "EX" },
	]);
	my $savedsearch = $results->item( 0 );

	my $screen;

	if( defined $savedsearch )
	{
		$screen = "View";
	}
	else
	{
		$screen = "Edit";
		$savedsearch = $ds->create_dataobj( {
			userid => $self->{session}->current_user->id,
			name => $self->{session}->xml->text_contents_of( $name ),
			spec => $searchexp->freeze
		} );
	}

	$self->{session}->xml->dispose( $name );

	my $url = URI->new( $self->{session}->config( "userhome" ) );
	$url->query_form(
		screen => "Workflow::$screen",
		dataset => "saved_search",
		dataobj => $savedsearch->id,
	);
	$self->{session}->redirect( $url );
	exit;
}

sub render_search_form
{
	my( $self ) = @_;

	if( $self->{processor}->{searchid} eq "simple" && @{$self->{processor}->{sconf}->{search_fields}} == 1 )
	{
		return $self->render_simple_form;
	}
	else
	{
		return $self->SUPER::render_search_form;
	}
}

sub render_preamble
{
	my( $self ) = @_;

	my $pphrase = $self->{processor}->{sconf}->{"preamble_phrase"};

	return $self->{session}->make_doc_fragment if !defined $pphrase;

	return $self->{session}->html_phrase( $pphrase );
}

sub render_simple_form
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $xhtml = $session->xhtml;
	my $xml = $session->xml;
	my $input;

	my $div = $xml->create_element( "div", class => "ep_block" );

	my $form = $self->{session}->render_form( "get" );
	$div->appendChild( $form );

	# avoid adding "dataset", which is selectable here
	$form->appendChild( $self->SUPER::render_hidden_bits );

	# maintain the order if it was specified (might break if dataset is
	# changed)
	$input = $xhtml->hidden_field( "order", $session->param( "order" ) );
	$form->appendChild( $input );

	$form->appendChild( $self->render_preamble );

	$form->appendChild( $self->{processor}->{search}->render_simple_fields( 'aria-labelledby' => $self->{session}->phrase( "lib/searchexpression:action_search" ) ) );

	$input = $xml->create_element( "input",
		type => "submit",
		name => "_action_search",
		value => $self->{session}->phrase( "lib/searchexpression:action_search" ),
		class => "ep_form_action_button",
		role => "button",
		id => $self->{session}->phrase( "lib/searchexpression:action_search" ),
	);
	$form->appendChild( $input );

	$input = $xml->create_element( "input",
		type => "submit",
		name => "_action_advanced",
		value => $self->{session}->phrase( "lib/searchexpression:advanced_link" ),
		class => "ep_form_action_button ep_form_search_advanced_link",
		role => "button",
	);
	$form->appendChild( $input );

	$form->appendChild( $xml->create_element( "br" ) );

	$form->appendChild( $self->render_dataset );

	return( $div );
}

sub render_dataset
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $xhtml = $session->xhtml;
	my $xml = $session->xml;

	my $frag = $xml->create_document_fragment;

	my @datasetids = $self->datasets;

	return $frag if @datasetids <= 1;

	foreach my $datasetid (sort @datasetids)
	{
		my $input = $xml->create_element( "input",
			name => "dataset",
			type => "radio",
			value => $datasetid );
		if( $datasetid eq $self->{processor}->{dataset}->id )
		{
			$input->setAttribute( checked => "yes" );
		}
		my $label = $xml->create_element( "label", id=>$datasetid );
		$frag->appendChild( $label );
		$label->appendChild( $input );
		$label->appendChild( $session->html_phrase( "datasetname_$datasetid" ) );
	}

	return $frag;
}

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from();

	my $processor = $self->{processor};
	my $repo = $self->{session};

	my $dataset = $processor->{dataset};
	my $searchid = $processor->{searchid};

	return if !defined $dataset;
	return if !defined $searchid;

	# get the dataset's search configuration
	my $sconf = $dataset->search_config( $searchid );
	$sconf = $self->default_search_config if !%$sconf;

	$processor->{sconf} = $sconf;
	$processor->{template} = $sconf->{template} if defined $sconf->{template};
}

sub default_search_config
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $repo = $self->{session};

	my $sconf = undef;

	#we haven't found an sconf in the config...
	#so try to derive an sconf from the searchid...
	my $searchid = $processor->{searchid};
	if( $searchid =~ /^([a-zA-z]+)_(\d+)_([a-zA-Z]+)/)
        {
		#get the sconf from the dataobj (this is probably an ingredients/eprints_list list)
		my $ds = $repo->dataset( $1 );
		if( defined $ds )
                {
                        my $dataobj = $ds->dataobj( $2 );
                        $sconf = $dataobj->get_sconf( $repo, $3 ) if defined $dataobj && $dataobj->can( "get_sconf" );
                }

	}
	return $sconf;
}

sub from
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $processor = $self->{processor};
	my $sconf = $processor->{sconf};

	# This rather oddly now checks for the special case of one parameter, but
	# that parameter being a screenid, in which case the search effectively has
	# no parameters and should not default to action = 'search'.
	# maybe this can be removed later, but for a minor release this seems safest.
	if( !EPrints::Utils::is_set( $self->{processor}->{action} ) )
	{
		my %params = map { $_ => 1 } $self->{session}->param();
		foreach my $param (keys %{{$self->hidden_bits}}) {
			delete $params{$param};
		}
		if( EPrints::Utils::is_set( $self->{session}->param( "output" ) ) )
		{
			$self->{processor}->{action} = "export";
		}
		elsif( scalar keys %params )
		{
			$self->{processor}->{action} = "search";
		}
		else
		{
			$self->{processor}->{action} = "";
		}
	}

	my $satisfy_all = $self->{session}->param( "satisfyall" );
	$satisfy_all = !defined $satisfy_all || $satisfy_all eq "ALL";

	my $searchexp = $processor->{search};
	if( !defined $searchexp )
	{
		my $format = $processor->{searchid} . "/" . $processor->{dataset}->base_id;
		if( !defined $sconf )
		{
			EPrints->abort( "No available configuration for search type $format" );
		}
		$searchexp = $session->plugin( "Search" )->plugins(
			{
				session => $session,
				dataset => $self->search_dataset,
				keep_cache => 1,
				satisfy_all => $satisfy_all,
				%{$sconf},
				filters => [
					$self->search_filters,
					@{$sconf->{filters} || []},
				],
			},
			type => "Search",
			can_search => $format,
		);
		if( !defined $searchexp )
		{
			EPrints->abort( "No available search plugin for $format" );
		}
		$processor->{search} = $searchexp;
	}

	if( $searchexp->is_blank && $self->{processor}->{action} ne "newsearch" )
	{
		my $ok = 0;
		if( my $id = $session->param( "cache" ) )
		{
			$ok = $searchexp->from_cache( $id );
		}
		if( !$ok && (my $exp = $session->param( "exp" )) )
		{
			# cache expired
			$ok = $searchexp->from_string( $exp );
		}
		if( !$ok )
		{
			for( $searchexp->from_form )
			{
				$self->{processor}->add_message( "warning", $_ );
			}
		}
	}

	$sconf->{order_methods} = {} if !defined $sconf->{order_methods};
	if( $searchexp->param( "result_order" ) )
	{
		$sconf->{order_methods}->{"byrelevance"} = $sconf->{default_order} ? "byrelevance" : "";
	}

	# have we been asked to reorder?
	if( defined( my $order_opt = $self->{session}->param( "order" ) ) )
	{
		my $allowed_order = 0;
		foreach my $custom_order ( values %{$sconf->{order_methods}} )
		{
			$allowed_order = 1 if $order_opt eq $custom_order;
		}

		my $custom_order;
		if( $allowed_order )
		{
			$custom_order = $order_opt;
		}
		elsif( defined $sconf->{default_order} )
		{
			$custom_order = $sconf->{order_methods}->{$sconf->{default_order}};
		}
		else
		{
			$custom_order = "";
		}

		$searchexp->{custom_order} = $custom_order;
	}
	# use default order
	else
	{
		$searchexp->{custom_order} = $sconf->{order_methods}->{$sconf->{default_order}};
	}

	# feeds are always limited and ordered by -datestamp
	if( $self->{processor}->{action} eq "export" )
	{
		my $output = $self->{session}->param( "output" );
		my $export_plugin = $self->{session}->plugin( "Export::$output" );
		if( !defined($self->{session}->param( "order" )) && defined($export_plugin) && $export_plugin->is_feed )
		{
			# borrow the max from latest_tool (which we're replicating anyway)
			my $limit = $self->{session}->config(
				"latest_tool_modes", "default", "max"
			);
			$limit = 20 if !$limit;
			my $n = $self->{session}->param( "n" );
			if( $n && $n > 0 && $n < $limit)
			{
				$limit = $n;
			}
			$searchexp->{limit} = $limit;
			$searchexp->{custom_order} = "-datestamp";
		}
	}

	# do actions
	$self->EPrints::Plugin::Screen::from;

	if( $searchexp->is_blank && $self->{processor}->{action} ne "export" )
	{
		if( $self->{processor}->{action} eq "search" )
		{
			$self->{processor}->add_message( "warning",
				$self->{session}->html_phrase(
					"lib/searchexpression:least_one" ) );
		}
		$self->{processor}->{search_subscreen} = "form";
	}
}

sub get_facet_config
{
	my( $self ) = @_;

	return [
		{
			field_id => "type"
		},
		{
			field_id => "department"
		},
		{
			field_id => "ispublished"
		},
		{
			field_id => "publisher"
		},
		{
			field_id => "publication"
		},
		{
			field_id => "date"
		},	];
}

sub get_facet_parameters
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $facets = {};

	foreach my $key ( $session->param() )
	{
		if( $key =~ /^facet_/ )
		{
			my @values = split( /\|/, $session->param( $key ) );

			$key =~ s/^facet_//;

			$facets->{$key} = \@values;
		}

	}

	return $facets;
}

sub get_facet_conditions
{
	my( $self, $ignore_facet ) = @_;

	my $search = $self->{processor}->{search};
	my $dataset = $self->{processor}->{dataset};

	my $facet_conditions;

	my $facets = $self->get_facet_parameters();

	foreach my $field_name ( keys %{ $facets } )
	{
		my $field = $dataset->get_field( $field_name );

		my $values = $facets->{$field_name};

		if( scalar @$values == 1 )
		{
			push @$facet_conditions, EPrints::Search::Condition::Comparison->new(
				"=", $dataset, $field, $values->[0]
			);
		}
		else
		{
			my @sub_conditions;

			foreach my $value ( @$values )
			{
				push @sub_conditions, EPrints::Search::Condition::Comparison->new(
					"=", $dataset, $field, $value
				);
			}

			push @$facet_conditions, EPrints::Search::Condition::Or->new( @sub_conditions );
		}
	}

	return $facet_conditions;
}

sub add_facets
{
	my( $self, $condition, $exclude ) = @_;

	my $search = $self->{processor}->{search};
	my $dataset = $self->{processor}->{dataset};

	my @facet_conditions = $condition;

	my $facet_conditions2 = $self->get_facet_conditions;

	my $facets = $self->get_facet_parameters();

	foreach my $field_name ( keys %{ $facets } )
	{
		if(( defined( $exclude )) && ( $field_name eq $exclude ))
		{
			next;
		}

		my $field = $dataset->get_field( $field_name );

		my $values = $facets->{$field_name};

		if( scalar @$values == 1 )
		{
			push @facet_conditions, EPrints::Search::Condition::Comparison->new(
				"=", $dataset, $field, $values->[0]
			);
		}
		else
		{
			my @sub_conditions;

			foreach my $value ( @$values )
			{
				push @sub_conditions, EPrints::Search::Condition::Comparison->new(
					"=", $dataset, $field, $value
				);
			}

			push @facet_conditions, EPrints::Search::Condition::Or->new( @sub_conditions );
		}
	}

	if( scalar @facet_conditions > 1 )
	{
		$condition = EPrints::Search::Condition::And->new( @facet_conditions );
	}

	return $condition;
}

sub run_search
{
	my( $self ) = @_;

	$self->{processor}->{search}->{condition_filter_function} = sub {
		return $self->add_facets( @_ );
	};

	$self->SUPER::run_search;
}


sub render_facet_list
{
	my( $self, $facet_config ) = @_;

	my $max_facet_list_length = 6;

	my $facet = $facet_config->{field_id};

	my $session = $self->{session};

	my $search = $self->{processor}->{search};
	my $dataset = $self->{processor}->{dataset};

	my %current_values;
	my $existing_param = $session->param( "facet_$facet" );

	if( defined( $existing_param ) )
	{
		foreach my $current_value (split( /\|/, $existing_param ))
		{
			$current_values{$current_value} = 1;
		}
	}

	my $base_url = $self->{session}->current_url( host => 1, query => 1 );
	my @query = $base_url->query_form;

	foreach my $i (reverse(0 .. int($#query/2)))
	{
		splice(@query, $i*2, 2) if $query[$i*2] eq "facet_$facet";
	}

	$base_url->query_form( @query );
	$base_url->query( undef ) if !@query;

	# print STDERR "Without $facet: $base_url\n";

	my $field = $self->{processor}->{dataset}->get_field( $facet );

	my $list = $session->make_element( "div" );


	my $old_condition_filter_function = $search->{condition_filter_function};


	$search->{condition_filter_function} = sub {
		return $self->add_facets( @_, $facet );
	};


	my $entries = $session->make_element( "ul", "class" => "ep_facet_entries", "data-ep-facet", $facet );

	my( $values, $counts ) = $search->perform_groupby( $field );

	my @result;
	my $num_results = scalar @{$counts};

	for (my $index = 0; $index < $num_results; $index++)
	{
		push @result, { count => $counts->[$index], value => $values->[$index] };
	}

	my @sorted_result = sort { $b->{count} <=> $a->{count} } @result;


	my $show_this_facet = 0;

	foreach my $result (@sorted_result)
	{
		if( defined( $result->{value} ) )
		{
			$show_this_facet = 1;
		}
	}

	if( $show_this_facet )
	{
		my $heading = $session->make_element( "h3", "class" => "ep_facet_heading" );
		$heading->appendChild( $session->make_text( $field->render_name ) );

		my @defined_results;

		foreach my $result (@sorted_result)
		{
			if( defined( $result->{value} ) )
			{
				push @defined_results, $result;
			}
		}

		my $show_expander = scalar( @defined_results) > $max_facet_list_length;

		for my $index (0 .. $#defined_results)
		{
			my $result = $defined_results[$index];

			# Show expander.

			if( $show_expander && ( $index == ( $max_facet_list_length - 1 ) ) )
			{
				my $expander = $session->make_element( "a", "class" => "ep_facet_show_more", "href" => "#" );

				my $num = 1 + scalar( @defined_results ) - $max_facet_list_length;

				$expander->appendChild( $session->make_text( "Show $num more...") );

				$entries->appendChild( $expander );
			}

			# Show facet list entry.

			my $entry = $session->make_element( "li",
				"style" => ( $show_expander && ( $index >= ( $max_facet_list_length - 1 ) ? "display: none" : undef) ),
				"class" => "ep_facet_entry" . ( defined( $result->{value} ) ? "" : " ep_facet_unspecified" ),
				"data-ep-facet-value" => defined( $result->{value} ) ? $result->{value} : "");

			my $checkbox = $session->make_element( "input",
				"title" => $result->{value},
				"type" => "checkbox",
				"checked" => $current_values{$result->{value}} );

			# my $label = $session->make_element( "span", "class" => "ep_facet_label" );
			my $label = $session->make_element( "a", "class" => "ep_facet_label", "href" => "#" );

			my $label_content;
			my $field_type = $field->type;

			if( ( $field_type eq "namedset" ) || ( $field_type eq "set" ) )
			{
				$label_content = $field->render_option( $session, $result->{value} );
			}
			else
			{
				$label_content = $result->{value};
			}

			if ( !defined( $label_content ) )
			{
				$label_content = "Unspecified";
			}

			$label->appendChild( $session->make_text( $label_content ) );

			my $count = $session->make_element( "span", "class" => "ep_facet_count" );
			$count->appendChild( $session->make_text( $result->{count} ) );

			$entry->appendChild( $checkbox );
			$entry->appendChild( $label );
			$entry->appendChild( $count );

			$entries->appendChild( $entry );
		}

		$list->appendChild( $heading );
		$list->appendChild( $entries );
	}

	$search->{condition_filter_function} = $old_condition_filter_function;

	return $list;
}

sub render_facet_lists
{
	my( $self ) = @_;

	my $facets = $self->get_facet_parameters();

	my $lists = $self->{session}->make_doc_fragment;

	# $lists->appendChild( $self->{session}->make_text( Data::Dumper->Dump([$facets], ['$facets']) ) );

	my $facet_config = $self->get_facet_config;

	foreach my $facet (@$facet_config)
	{
		$lists->appendChild( $self->render_facet_list( $facet ) );
	}

	return $lists;
}

sub render_results
{
	my( $self ) = @_;

	my $page = $self->{session}->make_doc_fragment;

	my $results = $self->{session}->make_element("div", "class" => "ep_search_result_area");

	if( $self->{processor}->{searchid} eq "advanced" )
	{
		my $facets_area = $self->{session}->make_element("div", "class" => "ep_facet_list");
		$facets_area->appendChild( $self->render_facet_lists() );

		$results->appendChild( $facets_area );
	}

	my $results_area = $self->{session}->make_element("div", "class" => "ep_search_result_list");
	$results_area->appendChild( $self->SUPER::render_results );

	$results->appendChild( $results_area );

	$page->appendChild( $results );

	return $page;
}

1;

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2023 University of Southampton.
EPrints 3.4 is supplied by EPrints Services.

http://www.eprints.org/eprints-3.4/

=end COPYRIGHT

=begin LICENSE

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

=end LICENSE

