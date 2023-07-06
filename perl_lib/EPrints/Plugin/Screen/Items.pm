=head1 NAME

EPrints::Plugin::Screen::Items

=cut


package EPrints::Plugin::Screen::Items;

use EPrints::Plugin::Screen::Listing;

@ISA = ( 'EPrints::Plugin::Screen::Listing' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{appears} = [
		{
			place => "key_tools",
			position => 125,
		}
	];

	$self->{actions} = [qw/ col_left col_right remove_col add_col /];

	return $self;
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $session = $self->{session};

	$processor->{dataset} = $session->dataset( "eprint" );

	$self->SUPER::properties_from();
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "items" );
}

sub allow_col_left { return $_[0]->can_be_viewed; }
sub allow_col_right { return $_[0]->can_be_viewed; }
sub allow_remove_col { return $_[0]->can_be_viewed; }
sub allow_add_col { return $_[0]->can_be_viewed; }

sub action_col_left
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	my $a = $newlist[$col_id];
	my $b = $newlist[$col_id-1];
	$newlist[$col_id] = $b;
	$newlist[$col_id-1] = $a;

	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}

sub action_col_right
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	my $a = $newlist[$col_id];
	my $b = $newlist[$col_id+1];
	$newlist[$col_id] = $b;
	$newlist[$col_id+1] = $a;

	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}
sub action_add_col
{
	my( $self ) = @_;

	my $col = $self->{session}->param( "col" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	push @newlist, $col;

	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}
sub action_remove_col
{
	my( $self ) = @_;

	my $col_id = $self->{session}->param( "colid" );
	my $v = $self->{session}->current_user->get_value( "items_fields" );

	my @newlist = @$v;
	splice( @newlist, $col_id, 1 );

	$self->{session}->current_user->set_value( "items_fields", \@newlist );
	$self->{session}->current_user->commit();
}

sub get_filters
{
	my( $self ) = @_;

	my $pref = $self->{id}."/eprint_status";
	my $user = $self->{session}->current_user;
	my @f = @{$user->preference( $pref ) || []};
	if( !scalar @f )
	{
		# sf2 - 2010-08-04 - define local filters
		my $lf = $self->{session}->config( "items_filters" );
		@f = ( defined $lf ) ? @$lf : ( inbox=>1, buffer=>1, archive=>1, deletion=>1 );
	}

	foreach my $i (0..$#f)
	{
		next if $i % 2;
		my $filter = $f[$i];
		my $v = $self->{session}->param( "set_show_$filter" );
		if( defined $v )
		{
			$f[$i+1] = $v;
			$user->set_preference( $pref, \@f );
			$user->commit;
			last;
		}
	}

	my @l = map { $f[$_] } grep { $_ % 2 == 0 && $f[$_+1] } 0..$#f;

	return (
		{ meta_fields => [qw( eprint_status )], value => "@l", match => "EQ", merge => "ANY" },
	);
}

sub render_title
{
	my( $self ) = @_;

	return $self->EPrints::Plugin::Screen::render_title();
}

sub perform_search
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $search = $processor->{search};

	# dirty hack to pass the internal search through to owned_eprints_list
	my $list = $self->{session}->current_user->owned_eprints_list( %$search,
		custom_order => $search->{order}
	);

	return $list;
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{session};
	my $user = $repo->current_user;

	### Get the items owned by the current user
	my $list = $self->perform_search;

	my $import_screen = $repo->plugin( "Screen::Import" );
	my $has_eprints = $user->owned_eprints_list()->count > 0;

	return $repo->template_phrase( "view:EPrints/Plugin/Screen/Items:render", { item => {
		has_eprints => $has_eprints,
		help_phrase => $has_eprints ? "Plugin/Screen/Items:help" : "Plugin/Screen/Items:help_no_items",
		item_tools => $self->render_action_list_bar( "item_tools" ),
		import_screen => defined $import_screen ? $import_screen->render_import_bar() : undef,
		eprints => $has_eprints ? $self->render_items( $list ) : undef,
	} } );
}

sub render_items
{
	my( $self, $list ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;
	my $ds = $session->dataset( "eprint" );

	my $pref = $self->{id}."/eprint_status";
	my %filters = @{$session->current_user->preference( $pref ) || [
		inbox=>1, buffer=>1, archive=>1, deletion=>1
	]};

	my $filter_info = {
		filters => [],
	};

	# EPrints Services/tmb 2011-02-15 add opportunity to bypass hardcoded order
	my @order = @{ $session->config( 'items_filters_order' ) || [] };
	@order = qw/ inbox buffer archive deletion / unless( scalar(@order) );
	# EPrints Services/tmb end

	foreach my $filter ( @order )
	{
		my $url = URI->new( $session->current_url() );
		my %q = $self->hidden_bits;
		$q{"set_show_$filter"} = !$filters{$filter};
		$url->query_form( %q );

		push $filter_info->{filters}, {
			id => $filter,
			active => $filters{$filter},
			url => $url,
		};
	}

	my $columns = $session->current_user->get_value( "items_fields" );
	@$columns = grep { $ds->has_field( $_ ) } @$columns;

	if( !EPrints::Utils::is_set( $columns ) )
	{
		$columns = [ "eprintid","type","eprint_status","lastmod" ];
		$session->current_user->set_value( "items_fields", $columns );
		$session->current_user->commit;
	}

	my $final_row = {
		columns => [],
		screen => 'Items',
		column_param => 'colid',
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
	my %opts = (
		params => {
			screen => "Items",
		},
		columns => [@{$columns}, undef ],
		above_results => $session->template_phrase( "view:EPrints/Plugin/Screen/Items:render_items/item_filters", { item => $filter_info } ),
		render_result => sub {

			my( $session, $eprint, $info ) = @_;

			my $locked = 0;
			my $locked_mine = 0;
			my $locked_other = 0;

			if( $eprint->is_locked )
			{
				$locked = 1;

				if( $eprint->get_value( "edit_lock_user" ) == $session->current_user->get_id )
				{
					$locked_mine = 1;
				}
				else
				{
					$locked_other = 1;
				}
			}

			my $item = {
				row_index => $info->{row},
				columns => [],
				status => $eprint->get_value( "eprint_status" ),
				locked => $locked,
				locked_mine => $locked_mine,
				locked_other => $locked_other,
			};

			my $column_index = 1;

			for( @$columns )
			{
				push $item->{columns}, {
					column => $_,
					column_index => $column_index++,
					render_value => $eprint->render_value( $_ ),
				};
			}

 			$self->{processor}->{eprint} = $eprint;
			$self->{processor}->{eprintid} = $eprint->get_id;

			$item->{action_list_icons} = $self->render_action_list_icons( "eprint_item_actions", { 'eprintid' => $self->{processor}->{eprintid} } );

			delete $self->{processor}->{eprint};

			++$info->{row};

			return $session->template_phrase( "view:EPrints/Plugin/Screen/Items:render_items/paginate_list", { item => $item } );
		},

		rows_after => $session->template_phrase( "view:EPrints/Plugin/Screen/Items:render_items/final_row", { item => $final_row } )
	);

	# Add form

	my $colcurr = {};
	my $fieldnames = {};

	foreach( @$columns ) { $colcurr->{$_} = 1; }

	foreach my $field ( $ds->get_fields )
	{
		next unless $field->get_property( "show_in_fieldlist" );
		next if $colcurr->{$field->get_name};

		my $name = EPrints::Utils::tree_to_utf8( $field->render_name( $session ) );
		my $parent = $field->get_property( "parent_name" );

		if( defined $parent )
		{
			my $pfield = $ds->get_field( $parent );
			$name = EPrints::Utils::tree_to_utf8( $pfield->render_name( $session )).": $name";
		}

		$fieldnames->{$field->get_name} = $name;
	}

	my @tags = sort { $fieldnames->{$a} cmp $fieldnames->{$b} } keys %$fieldnames;

	my $add_column_option_list = $session->render_option_list(
		name => 'col',
		height => 1,
		multiple => 0,
		'values' => \@tags,
		labels => $fieldnames );

	return $session->template_phrase( "view:EPrints/Plugin/Screen/Items:render_items", {
		item => {
			screen => 'Items',
			paginated_list => EPrints::Paginate::Columns->paginate_list( $session, "_buffer", $list, %opts ),
			add_column_option_list => $add_column_option_list,
		}
	});
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

