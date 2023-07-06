=head1 NAME

EPrints::Plugin::Screen::Listing

=cut

package EPrints::Plugin::Screen::Listing;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
#		{
#			place => "key_tools",
#			position => 100,
#		}
	];

	$self->{actions} = [qw/ search newsearch col_left col_right remove_col add_col set_filters reset_filters /];

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $session = $self->{session};

	if( !defined $processor->{dataset} )
	{
		my $datasetid = $session->param( "dataset" );

		if( $datasetid )
		{
			$processor->{"dataset"} = $session->dataset( $datasetid );
		}
	}

	my $dataset = $processor->{"dataset"};
	if( !defined $dataset )
	{
		$processor->{screenid} = "Error";
		$processor->add_message( "error", $session->html_phrase(
			"lib/history:no_such_item",
			datasetid=>$session->make_text( $session->param( "dataset" ) ),
			objectid=>$session->make_text( "" ) ) );
		return;
	}

	if( !defined $processor->{columns_key} )
	{
		$processor->{columns_key} = "screen.listings.columns.".$dataset->id;
	}

	if( !defined $processor->{filters_key} )
	{
		$processor->{filters_key} = "screen.listings.filters.".$dataset->id;
	}

	my $columns = $self->show_columns();
	$processor->{"columns"} = $columns;
	my %columns = map { $_->name => 1 } @$columns;

	my $order = $session->param( "_listing_order" );
	if( !EPrints::Utils::is_set( $order ) )
	{
		# default to ordering by the first column
		$order = join '/', map {
			($_->should_reverse_order ? '-' : '') . $_->name
		} (@$columns)[0];
	}
	else
	{
		# remove any order-bys that aren't visible
		$order = join '/', 
			map { ($_->[0] ? '-' : '') . $_->[1] }
			grep { $columns{$_->[1]} }
			map { [ $_ =~ s/^-//, $_ ]}
			split /\//, $order;
	}

	my $filters = [$self->get_filters];
	my $priv = $self->{processor}->{dataset}->id . "/view";
	if( !$self->allow( $priv ) )
	{
		if( $self->allow( "$priv:owner" ) )
		{
			push @$filters, {
				meta_fields => [qw( userid )], value => $session->current_user->id,
			};
		}
	}

	$self->{processor}->{search} = $dataset->prepare_search(
		filters => $filters,
		search_fields => [
			(map { { meta_fields => [$_->name] } } @$columns)
		],
		custom_order => $order,
	);

	$self->SUPER::properties_from;
}

sub from
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $search = $self->{processor}->{search};
	my $exp = $session->param( "exp" );
	my $action = $self->{processor}->{action};
	$action = "" if !defined $action;

	if( $action ne "newsearch" )
	{
		if( $exp )
		{
			my $order = $search->{custom_order};
			$search->from_string( $exp );
			$search->{custom_order} = $order;
		}
		else
		{
			foreach my $sf ( $search->get_non_filter_searchfields )
			{
				my $prob = $sf->from_form();
				if( defined $prob )
				{
					$self->{processor}->add_message( "warning", $prob );
				}
			}
		}
	}

	# don't apply the user filters (/preferences) if they're about to be changed or reset
	unless( $action eq 'set_filters' || $action eq 'reset_filters' )
	{
		$self->apply_user_filters();
	}

	$self->SUPER::from();
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	my $uri = URI->new( $self->SUPER::redirect_to_me_url );
	$uri->query_form(
		$uri->query_form,
		$self->hidden_bits,
	);

	return $uri;
}

sub can_be_viewed
{
	my( $self ) = @_;

	my $priv = $self->{processor}->{dataset}->id . "/view";

	return $self->allow( $priv ) || $self->allow( "$priv:owner" ) || $self->allow( "$priv:editor" );
}

sub allow_action
{
	my( $self, $action ) = @_;

	return $self->can_be_viewed();
}

sub action_search
{
}

sub action_newsearch
{
}

sub _set_user_columns
{
	my( $self, $columns ) = @_;

	my $user = $self->{session}->current_user;

	$user->set_preference( $self->{processor}->{columns_key}, join( " ", map { $_->name } @$columns ) );
	$user->commit;

	# update the list of columns
	$self->{processor}->{columns} = $self->show_columns();
}

sub action_col_left
{
	my( $self ) = @_;

	my $i = $self->{session}->param( "column" );
	return if !defined $i || $i !~ /^[0-9]+$/;

	my $columns = $self->{processor}->{columns};
	@$columns[$i-1,$i] = @$columns[$i,$i-1];

	$self->_set_user_columns( $columns );
}
sub action_col_right
{
	my( $self ) = @_;

	my $i = $self->{session}->param( "column" );
	return if !defined $i || $i !~ /^[0-9]+$/;

	my $columns = $self->{processor}->{columns};
	@$columns[$i+1,$i] = @$columns[$i,$i+1];

	$self->_set_user_columns( $columns );
}
sub action_add_col
{
	my( $self ) = @_;

	my $name = $self->{session}->param( "column" );
	return if !defined $name;
	my $field = $self->{processor}->{dataset}->field( $name );
	return if !defined $field;
	return if !$field->get_property( "show_in_fieldlist" );

	my $columns = $self->{processor}->{columns};
	push @$columns, $field;

	$self->_set_user_columns( $columns );
}
sub action_remove_col
{
	my( $self ) = @_;

	my $i = $self->{session}->param( "column" );
	return if !defined $i || $i !~ /^[0-9]+$/;

	my $columns = $self->{processor}->{columns};
	splice( @$columns, $i, 1 );

	$self->_set_user_columns( $columns );
}

sub action_set_filters
{
        my( $self ) = @_;

        my $user = $self->{session}->current_user;

        my @filters = ();
        foreach my $sf ( $self->{processor}->{search}->get_non_filter_searchfields )
        {
		push @filters, $sf->serialise;
        }

        $user->set_preference( $self->{processor}->{filters_key}, \@filters );
        $user->commit;

	$self->{session}->redirect( $self->redirect_to_me_url );
	return;
}

sub action_reset_filters
{
        my( $self ) = @_;

        $self->{session}->current_user->set_preference( $self->{processor}->{filters_key}, undef );
        $self->{session}->current_user->commit();

	$self->{session}->redirect( $self->redirect_to_me_url );
	return;
}

sub get_filters
{
	my( $self ) = @_;

	return ();
}

sub get_user_filters
{
        my( $self ) = @_;

	my @filters;

        my $pref = $self->{session}->current_user->preference( $self->{processor}->{filters_key} );

        if( EPrints::Utils::is_set( $pref ) && ref( $pref ) eq 'ARRAY' )
        {
                push @filters, $_ for( @$pref );
        }

        return @filters;
}

sub apply_user_filters
{
	my( $self ) = @_;

	my @user_filters = $self->get_user_filters;

	foreach my $uf ( @user_filters )
	{
		my $sf = EPrints::Search::Field->unserialise( repository => $self->{session}, 
			dataset => $self->{processor}->{dataset}, 
			string => $uf 
		);
		next unless( defined $sf );

		$self->{processor}->{search}->add_field( fields => $sf->get_fields, 
			value => $sf->get_value, 
			match => $sf->get_match, 
			merge => $sf->get_merge 
		);
	}
}

sub perform_search
{
	my( $self ) = @_;

	return $self->{processor}->{search}->perform_search;
}

sub render_links
{
	my( $self ) = @_;

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Listing:render_links" );
}

sub show_columns
{
	my( $self ) = @_;

	my $dataset = $self->{processor}->{dataset};
	my $user = $self->{session}->current_user;

	my $columns = $user->preference( $self->{processor}->{columns_key} );
	if( defined $columns )
	{
		$columns = [split / /, $columns];
		$columns = [grep { defined $_ } map { $dataset->field( $_ ) } @$columns];
	}
	if( !defined $columns || @{$columns} == 0 )
	{
		$columns = $dataset->columns();
	}
	if( !defined $columns || @{$columns} == 0 )
	{
		$columns = [$dataset->fields];
		splice(@$columns,4);
	}

	return $columns;
}

sub render_title
{
	my( $self ) = @_;

	my $session = $self->{session};

	return $session->html_phrase( "Plugin/Screen/Listing:page_title",
		dataset => $session->html_phrase( "datasetname_".$self->{processor}->{dataset}->id ) );
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;

	### Get the items owned by the current user
	my $ds = $self->{processor}->{dataset};

	my $search = $self->{processor}->{search};
	my $list = $self->perform_search;
	my $exp;
	if( !$search->is_blank )
	{
		$exp = $search->serialise;
	}

	my $columns = $self->{processor}->{columns};

	my $len = scalar @{$columns};

	# Get the current object as this can be inherited.
	my $screen = ref $self;
	$screen =~ s/.*://;

	my $final_row = {
		columns => [],
		column_param => 'column',
		screen => $screen,
		hidden_bits => $self->render_hidden_bits,
	};

	my $column_count = scalar @{$columns};

	for( my $i = 0; $i < $column_count; $i++ )
	{
		push $final_row->{columns}, {
			column => $columns->[$i],
			column_index => $i,
		};
	}

	# Paginate list
	my $row = 0;
	my %opts = (
		params => {
			screen => $self->{processor}->{screenid},
			exp => $exp,
			$self->hidden_bits,
		},
		custom_order => $search->{custom_order},
		columns => [(map{ $_->name } @{$columns}), undef ],
		above_results => $session->make_doc_fragment,
		render_result => sub {

			my( undef, $dataobj, $info ) = @_;

			local $self->{processor}->{dataobj} = $dataobj;

			my $item = {
				row_index => $info->{row},
				columns => [],
			};

			my $column_index = 1;

			for( map { $_->name } @$columns )
			{
				push $item->{columns}, {
					column => $_,
					column_index => $column_index++,
					render_value => $dataobj->render_value( $_ ),
				};
			}

			$item->{action_list_icons} = $self->render_dataobj_actions( $dataobj );

			++$info->{row};

			return $session->template_phrase( "view:EPrints/Plugin/Screen/Listing:render/render_result", { item => $item } );
		},

		rows_after => $session->template_phrase( "view:EPrints/Plugin/Screen/Items:render_items/final_row", { item => $final_row } )
	);

	$opts{page_size} = $self->param( 'page_size' );

	my $paginated_list = EPrints::Paginate::Columns->paginate_list( $session, "_listing", $list, %opts );

	# Add form
	my %col_shown = map { $_->name() => 1 } @$columns;
	my $fieldnames = {};
	foreach my $field ( $ds->fields )
	{
		next if !$field->get_property( "show_in_fieldlist" );
		next if $col_shown{$field->name};
		my $name = EPrints::Utils::tree_to_utf8( $field->render_name( $session ) );
		my $parent = $field->get_property( "parent_name" );
		if( defined $parent ) 
		{
			my $pfield = $ds->field( $parent );
			$name = EPrints::Utils::tree_to_utf8( $pfield->render_name( $session )).": $name";
		}
		$fieldnames->{$field->name} = $name;
	}

	my @tags = sort { $fieldnames->{$a} cmp $fieldnames->{$b} } keys %$fieldnames;
	# End of Add form

	my $add_column_option_list = $session->render_option_list( 
		name => 'column',
		height => 1,
		multiple => 0,
		'values' => \@tags,
		labels => $fieldnames );

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Listing:render", { item => {
		top_bar => $self->render_top_bar,
		filters => $self->render_filters,
		paginated_list => $paginated_list,
		screen => 'Listing',
		hidden_bits => $self->render_hidden_bits,
		add_column_option_list => $add_column_option_list,
	} } );
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		dataset => $self->{processor}->{dataset}->id,
		_listing_order => $self->{processor}->{search}->{custom_order},
		$self->SUPER::hidden_bits,
	);
}

sub render_top_bar
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $has_intro = !!$session->get_lang->has_phrase( $self->html_phrase_id( "intro" ), $session );

	my $dataobj_tools = $self->render_action_list_bar( "dataobj_tools", {
		dataset => $self->{processor}->{dataset}->id,
	} );

	return $session->template_phrase( "view:EPrints/Plugin/Screen/Listing:render_top_bar", { item => {
		has_intro => $has_intro,
		intro => $has_intro ?  $self->html_phrase( "intro" ) : undef,
		data_objtools => $dataobj_tools,
	} } );
}

sub render_dataobj_actions
{
	my( $self, $dataobj ) = @_;

	my $datasetid = $self->{processor}->{dataset}->base_id;

	return $self->render_action_list_icons( ["${datasetid}_item_actions", "dataobj_actions"], {
			dataset => $datasetid,
			dataobj => $dataobj->id,
		} );
}

sub render_filters
{
	my( $self ) = @_;

	my $session = $self->{session};

	return $session->template_phrase( "view:EPrints/Plugin/Screen/Listing:render_filters", { item => {
		form => $self->render_search_form(),
		collapsed => $self->{processor}->{search}->is_blank(),
		title => $session->html_phrase( "lib/searchexpression:action_filter" ),
	} } );
}

sub render_search_form
{
	my( $self ) = @_;

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Listing:render_search_form", { item => {
		hidden_bits => $self->render_hidden_bits,
		search_fields => $self->render_search_fields,
		# anyall_field => $self->render_anyall_field,
		controls => $self->render_controls,
	} } );
}


sub render_search_fields
{
	my( $self ) = @_;

	my $frag = $self->{session}->make_doc_fragment;

	foreach my $sf ( $self->{processor}->{search}->get_non_filter_searchfields )
	{
		my $field;
		my $ft = $sf->{"field"}->get_type();
		my $prefix = $sf->get_form_prefix;
		if ( ( $ft eq "set" || $ft eq "namedset" ) && $sf->{"field"}->{search_input_style} eq "checkbox" )
        {
            $field = $sf->render( legend => EPrints::Utils::tree_to_utf8( $sf->render_name ) . " " . EPrints::Utils::tree_to_utf8( $self->{session}->html_phrase( "lib/searchfield:desc:set_legend_suffix" ) ) );
            $prefix .= "_legend";
        }
        else
		{
            $field = $sf->render();
        }
		$frag->appendChild( 
			$self->{session}->render_row_with_help( 
				prefix => $prefix,
				help_prefix => $sf->get_form_prefix."_help",
				help => $sf->render_help,
				label => $sf->render_name,
				field => $field,
				no_toggle => ( $sf->{show_help} eq "always" ),
				no_help => ( $sf->{show_help} eq "never" ),
			 ) );
	}

	return $frag;
}


sub render_anyall_field
{
	my( $self ) = @_;

	my @sfields = $self->{processor}->{search}->get_non_filter_searchfields;
	if( (scalar @sfields) < 2 )
	{
		return $self->{session}->make_doc_fragment;
	}

	my $menu = $self->{session}->render_option_list(
			name=>"satisfyall",
			values=>[ "ALL", "ANY" ],
			default=>( defined $self->{processor}->{search}->{satisfy_all} && $self->{processor}->{search}->{satisfy_all}==0 ?
				"ANY" : "ALL" ),
			labels=>{ "ALL" => $self->{session}->phrase( 
						"lib/searchexpression:all" ),
				  "ANY" => $self->{session}->phrase( 
						"lib/searchexpression:any" )} );

	return $self->{session}->render_row_with_help( 
			no_help => 1,
			label => $self->{session}->html_phrase( 
				"lib/searchexpression:must_fulfill" ),  
			field => $menu,
	);
}

sub render_controls
{
	my( $self ) = @_;

	my $search_buttons = $self->{session}->render_action_buttons(
		set_filters => $self->{session}->phrase( "lib/searchexpression:action_filter" ),
		reset_filters => $self->{session}->phrase( "lib/searchexpression:action_reset" ),
		_order => [ "set_filters", "reset_filters" ],
	);

	return $self->{session}->template_phrase( "view:EPrints/Plugin/Screen/Listing:render_controls", { item => {
		search_buttons => $search_buttons,
	} } );
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

