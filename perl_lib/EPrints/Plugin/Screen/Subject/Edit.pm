=head1 NAME

EPrints::Plugin::Screen::Subject::Edit

=encoding utf8

=head1 METHODS

=cut


package EPrints::Plugin::Screen::Subject::Edit;

use EPrints::Plugin::Screen::Workflow::Edit;
@ISA = qw( EPrints::Plugin::Screen::Workflow::Edit );

use Digest::MD5 qw( md5 );
use JSON;
use List::Util qw( max min );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{actions} = [qw/ cancel save create link unlink remove /];

	$self->{appears} = [
		{
			place => "admin_actions_config",
			position => 2000,
		},
	];

	return $self;
}

sub has_workflow { 1 }
sub workflow
{
	my( $self ) = @_;

	return $self->SUPER::workflow( "screen_subject_edit" );
}

sub allow_cancel { 1 }
sub action_cancel {}

sub allow_save { 1 }
sub allow_create { 1 }
sub allow_link { 1 }
sub allow_unlink { 1 }
sub allow_remove { 1 }

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->EPrints::Plugin::Screen::allow( "subject/edit" );
}

sub properties_from
{
	my( $self ) = @_;

	my $processor = $self->{processor};

	$processor->{dataset} = $self->{session}->dataset( "subject" );

	my $id = $self->{session}->param( "dataobj" );
	if( !EPrints::Utils::is_set( $id ) )
	{
		$processor->{dataobj} = $processor->{dataset}->dataobj( "ROOT" );
	}

	$self->SUPER::properties_from;
}

sub render_title
{
	my( $self ) = @_;

	my $subject = $self->{processor}->{dataobj};

	my $f = $self->{session}->make_doc_fragment;
	$f->appendChild( $self->html_phrase( "title" ) );
	$f->appendChild( $self->{session}->make_text( ": " ) );

	my $title = $subject->render_citation( "screen" );
	$f->appendChild( $title );

	return $f;
}

sub render
{
	my( $self ) = @_;

	if( my $component = $self->current_component )
	{
		my $form = $self->render_form;
		$form->appendChild( $component->render );
		return $form;
	}

	my $session = $self->{session};
	my $subject = $self->{processor}->{dataobj};

	my $page = $session->make_doc_fragment;

#	$page->appendChild( $self->html_phrase( "subjectid", 
#		id=>$session->make_text( $subject->get_value( "subjectid" ) ) ) );

	$page->appendChild( $self->render_subject_tree );
	if( $subject->get_id ne $EPrints::DataObj::Subject::root_subject )
	{
		$page->appendChild( $self->render_editbox );
	}

	return $page;
}

sub render_editbox
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $processor = $self->{processor};

	my $form = $session->render_form( "POST" );
	$form->appendChild( $self->render_hidden_bits );

	my $workflow = $self->workflow;

	my $stage = $workflow->get_stage( $workflow->get_first_stage_id );

	# prepend subjectid ???
	$form->appendChild( $stage->render( $session, $workflow ) );

	$form->appendChild( $session->render_hidden_field( "_default_action", "register" ) );
	$form->appendChild( $session->render_action_buttons(
		save => $self->phrase( "action_save" )
		) );

	$form->appendChild( $session->make_text( "History (TODO: formatting):" ) );
	my $parent = $processor->{dataobj};
	my $list = $session->dataset( 'history' )->search(
		filters => [
			{ meta_fields => [qw( datasetid )], value => 'subject' },
			{ meta_fields => [qw( objectid )], value => unpack( 'l', md5( $parent->id ) ) },
		],
		custom_order => '-historyid',
	);
	$form->appendChild( EPrints::Paginate->paginate_list(
		$session,
		undef,
		$list,
		params => { $processor->{screen}->hidden_bits },
		container => $session->make_element( 'div' ),
		render_result => sub {
			my( undef, $item ) = @_;
			return $self->render_history( $item, $parent->id );
		},
	) );

	return $form;
}

sub action_save
{
	my( $self ) = @_;

	my $processor = $self->{processor};
	my $subject = $processor->{dataobj};

	my $workflow = $self->workflow;

	if( $workflow->update_from_form( $processor, $workflow->get_stage_id, 0 ) )
	{
		$processor->add_message( "message", $self->html_phrase( "saved" ) );
		$subject->commit();
	}
}


###############################

sub render_subject_tree
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $subject = $self->{processor}->{dataobj};
	my $dataset = $subject->get_dataset;

	my $tree = {
		$EPrints::DataObj::Subject::root_subject => $self->render_subject( $dataset->dataobj( $EPrints::DataObj::Subject::root_subject ), 1 ),
	};

	$self->_render_subject_tree( $tree, $subject, {} );

	return $tree->{$EPrints::DataObj::Subject::root_subject};
}

sub _render_subject_tree
{
	my( $self, $tree, $current, $seen ) = @_;

	return undef if $seen->{$current->id}++;
#	EPrints->abort( "subject hierarchy cycle encountered on ".$current->id )
#		if $seen->{$current->id};

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $subject = $self->{processor}->{dataobj};
	my $dataset = $subject->get_dataset;

	my $ul;

	my $first = 1;
	foreach my $parent ($current->get_parents)
	{
		my $container = $tree->{$parent->id};
		if( !defined $container )
		{
			$container = $self->_render_subject_tree( $tree, $parent, $seen );
			if( !defined $container )
			{
				$self->{processor}->add_message( "error", $self->html_phrase( "loop",
					id => $self->{session}->make_text( $current->id ),
				) );
				next;
			}
			$tree->{$parent->id} = $container;
		}
		# ul -> li
		$container->firstChild->appendChild( $ul = $self->render_subject( $current, $first ) );
		$first = 0;
	}

	return defined $ul ? $ul : $self->render_subject( $current );
}

sub render_subject
{
	my( $self, $current, $show_children ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $subject = $self->{processor}->{dataobj};
	my $dataset = $subject->get_dataset;

	my $ul = $xml->create_element( "ul" );

	my $li = $ul->appendChild( $xml->create_element( "li" ) );
	if( $current->id eq $subject->id )
	{
		$li->appendChild( $xml->create_data_element( "strong",
			$current->render_citation( "edit",
				pindata => {
					inserts => {
						n => $xml->create_text_node( $current->count_eprints( $repo->dataset( "eprint" ) ) ),
						a => $xml->create_text_node( $current->count_eprints( $repo->dataset( "archive" ) ) ),
					},
				},
			)
		) );
		$li->appendChild( $self->render_children )
			if $show_children;
	}
	else
	{
		local $self->{processor}->{dataobj} = $current;
		my $url = $repo->current_url( path => "cgi", "users/home" );
		$url->query_form( $self->hidden_bits );
		$li->appendChild( $current->render_citation( "edit",
			url => $url,
			pindata => {
				inserts => {
					n => $xml->create_text_node( $current->count_eprints( $repo->dataset( "eprint" ) ) ),
					a => $xml->create_text_node( $current->count_eprints( $repo->dataset( "archive" ) ) ),
				},
			},
		) );
	}

	return $ul;
}

sub render_children
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $subject = $self->{processor}->{dataobj};
	my $dataset = $subject->get_dataset;

	my $table = $xml->create_element( "table",
		border => 0,
		cellpadding => 4,
		cellspacing => 0,
		class => "ep_columns",
		style => "margin: 0px 0px",
	);

	my $tr = $table->appendChild( $xml->create_element( "tr",
		class => "",
	) );

	$tr->appendChild( $xml->create_data_element( "th",
		$self->phrase( "children" ),
		class => "ep_columns_title",
	) );

	$tr->appendChild( $xml->create_data_element( "th",
		$self->phrase( "eprints" ),
		class => "ep_columns_title",
	) );

	$tr->appendChild( $xml->create_data_element( "th",
		$self->phrase( "actions" ),
		class => "ep_columns_title",
	) );

	# child subjects
	foreach my $child ($subject->get_children)
	{
		my $tr = $table->appendChild( $xml->create_element( "tr",
			class => ""
		) );
		my $url = $repo->current_url( path => "cgi", "users/home" );
		{
			local $self->{processor}->{dataobj} = $child;
			$url->query_form( $self->hidden_bits );
		}
		my $td = $tr->appendChild( $xml->create_element( "td",
			class => "ep_columns_cell",
		) );
		$td->appendChild( $child->render_citation( "edit",
			url => $url,
		) );
		$td = $tr->appendChild( $xml->create_element( "td",
			class => "ep_columns_cell",
			style => "text-align: right",
		) );
		$td->appendChild( $xml->create_text_node( $child->count_eprints( $repo->dataset( "eprint" ) ) . ' (' . $child->count_eprints( $repo->dataset( "archive" ) ) . ')' ) );

		$td = $tr->appendChild( $xml->create_element( "td",
			class => "ep_columns_cell",
		) );

		my $idsuffix = EPrints::Utils::sanitise_element_id( $child->id . "_unlink" );
		my $form = $td->appendChild( $self->render_form( $idsuffix ) );
		$form->appendChild( $xhtml->hidden_field( childid => $child->id, id => "childid_" . $idsuffix ) );
		$form->appendChild( $xhtml->action_button(
			unlink => $self->phrase( "action_unlink" )
		) );
	}

	# create new child
	{
		my $tr = $table->appendChild( $xml->create_element( "tr",
			class => "",
		) );
		my $td = $tr->appendChild( $xml->create_element( "td",
			class => "ep_columns_cell",
			colspan => 3,
		) );
		my $form = $td->appendChild( $self->render_form( "create_subject" ) );
		my $label = $xml->create_element( "label", "for"=>'new_childid' ); 
		$label->appendChild( $dataset->field( "subjectid" )->render_name );
		$form->appendChild( $label );
		$form->appendChild( $xml->create_text_node( ": " ) );
		$form->appendChild( $xhtml->input_field( childid => undef, id => "new_childid" ) );
		$form->appendChild( $xhtml->action_button(
			create => $repo->phrase( "lib/submissionform:action_create" )
		) );
	}

	# link existing child
	{
		my $tr = $table->appendChild( $xml->create_element( "tr",
			class => "",
		) );
		my $td = $tr->appendChild( $xml->create_element( "td",
			class => "ep_columns_cell",
			colspan => 3,
		) );
		my $form = $td->appendChild( $self->render_form( "link_subject" ) );
		$form->appendChild( $self->html_phrase( "existing" ) );
		$form->appendChild( $xml->create_text_node( ": " ) );
		my $select = $form->appendChild( $xml->create_element( "select",
			name => "childid",
			'aria-labelledby' => "existing_childid_label",
		) );
		$subject->get_dataset->search->map(sub {
			my( undef, undef, $child ) = @_;

			$select->appendChild( $xml->create_data_element( "option",
				$child->id,
				value => $child->id,
			) );
		});
		$form->appendChild( $xhtml->action_button(
			link => $self->phrase( "action_link" )
		) );
	}

	return $table;
}

sub render_history
{
	my( $self, $item, $objectid ) = @_;
	my $repo = $self->{repository};

	sub render_data_structure {
		my( $session, $value ) = @_;
		my $pre = $session->make_element( 'pre', class => 'ep_history_xmlblock', style => 'white-space: pre-wrap;' );
		if( ref( $value ) eq 'ARRAY' ) {
			my @array = @{$value};
			my $text = '[';
			if( scalar @array ) {
				for my $item (@array) {
					$text .= "\n  $item,";
				}
				$text .= "\n]";
			} else {
				$text .= ']';
			}
			$pre->appendChild( $session->make_text( $text ) );
		} else {
			$pre->appendChild( $session->make_text( $value ) );
		}
		return $pre;
	}

	my %pins = ();
	my $user = $item->get_user;

	my $datasetid = $item->get_value( 'datasetid' );
	$item->set_value( 'objectid', $objectid );
	if( defined $item->get_dataobj ) {
		$pins{item} = $repo->make_doc_fragment;
		$pins{item}->appendChild( $item->get_dataobj->render_description );
		my $revision = $item->get_value( 'revision' );
		$pins{item}->appendChild( $repo->make_text( " ($datasetid $objectid r$revision)" ) );
	} else {
		$pins{item} = $repo->html_phrase(
			'lib/history:no_such_item',
			datasetid => $repo->make_text( $datasetid ),
			objectid => $repo->make_text( $objectid ),
		);
	}

	if( defined $user ) {
		$pins{cause} = $user->render_description;
	} else {
		$pins{cause} = $repo->make_element( 'tt' );
		$pins{cause}->appendChild( $repo->make_text( $item->get_value( 'actor' ) ) );
	}

	$pins{when} = $item->render_value( 'timestamp' );
	$pins{action} = $item->render_value( 'action' );

	$pins{details} = $repo->make_element( 'table', class => 'ep_history_diff_table' );
	my $tr = $pins{details}->appendChild( $repo->make_element( 'tr' ) );
	my $td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 10%;' ) );
	$td->appendChild( $repo->make_text( 'Field' ) ); # TODO: Phrase this
	$td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 45%;' ) );
	$td->appendChild( $repo->html_phrase( 'lib/history:before' ) );
	$td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 45%;' ) );
	$td->appendChild( $repo->html_phrase( 'lib/history:after' ) );

	my $values = from_json( $item->get_value( 'details' ) );
	for my $fields (@{$values}) {
		my( $field, $old_value, $new_value ) = @{$fields};

		my $tr = $pins{details}->appendChild( $repo->make_element( 'tr' ) );
		my $th = $tr->appendChild( $repo->make_element( 'th', style => 'width: 10%;' ) );
		$th->appendChild( $repo->html_phrase( "subject_fieldname_$field" ) );
		my $td = $tr->appendChild( $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' ) );
		$td->appendChild( render_data_structure( $repo, $old_value ) );
		$td = $tr->appendChild( $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' ) );
		$td->appendChild( render_data_structure( $repo, $new_value ) );
	}

	return $repo->html_phrase( 'lib/history:record', %pins );
}

######################################################################
=pod

=over 4

=item $text = $screen->render_history_diff( $left, $right )

Returns two <td> elements (left and right) to show the difference between the
passed in C<$left> and C<$right> items.

This currently supports (both sides must match or the left must be C<undef>):

=over 4

=item * Numbers  - Displayed as -3.14

=item * Strings  - Displayed as "Hello"

=item * C<undef> - Displayed as UNSPECIFIED

=back

=cut
######################################################################

sub render_history_diff
{
	my( $self, $left, $right ) = @_;
	my $repo = $self->{repository};
	my $width = ($repo->config( 'max_history_width' ) || 120) / 2;

	sub render_scalar {
		my( $repo, $value ) = @_;
		if( $value =~ /^-?\d*(?:\.?\d+)$/ ) { # Display anything that looks like a number 'as-is'
			return $value;
		} elsif( defined $value ) { # Display any defined non-numbers as strings
			return "\"$value\"";
		} else { # Display undef as 'UNSPECIFIED'
			return $repo->phrase( 'lib/metafield:unspecified' );
		}
	}

	sub render_list_portion {
		my( $repo, @list ) = @_;
		my $text = '';
		for my $item (@list) {
			$text .= "\n  " . render_scalar( $repo, $item ) . ',';
		}
		return $text;
	}

	my $td_left = $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' );
	my $td_right = $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' );
	my $pre_left = $td_left->appendChild( $repo->make_element( 'pre', class => 'ep_history_xmlblock' ) );
	my $pre_right = $td_right->appendChild( $repo->make_element( 'pre', class => 'ep_history_xmlblock' ) );

	# If the left is undefined then this field has been set for the first time
	if( !defined $left ) {
		if( ref( $right ) eq 'ARRAY' ) {
			my( $created, $line_count ) = wrap_text( '[' . render_list_portion( $repo, @{$right} ) . "\n]", $width );
			my $left_span = $pre_left->appendChild( $repo->make_element( 'span' ) );
			$left_span->appendChild( $repo->make_text( "\n" x $line_count ) );
			$pre_right->appendChild( $repo->make_text( $created ) );
		} else {
			$pre_left->appendChild( $repo->render_nbsp );
			$pre_right->appendChild( $repo->make_text( render_scalar( $repo, $right ) ) );
		}

		delete $td_left->{class};
		$td_right->{class} = 'ep_history_diff_table_add';

		return( $td_left, $td_right );
	} elsif( ref( $right ) ne 'ARRAY' ) {
		my $left_span = $pre_left->appendChild( $repo->make_element( 'span', style => 'background: #cc0;' ) );
		my $right_span = $pre_right->appendChild( $repo->make_element( 'span', style => 'background: #cc0;' ) );

		$left_span->appendChild( $repo->make_text( render_scalar( $repo, $left ) ) );
		$right_span->appendChild( $repo->make_text( render_scalar( $repo, $right ) ) );

		return( $td_left, $td_right );
	}

	return( $td_left, $td_right );
}

######################################################################
=pod

=item $text = Self::wrap_text( $text: str, $width: int )

=item ($text, $lines) = Self::wrap_text( $text: str, $width: int )

This wraps the given C<text> to a maximum width of C<width>, adding (↲) to
denote line breaks. If called in ARRAY context it will also return the
line count of the new text.

=cut
######################################################################

sub wrap_text
{
	my( $text, $width ) = @_;

	my $line_break = chr(8626); # The character to use as a line break (↲)
	my @lines = ();
	foreach my $line ( split /[\r\n]/, $text ) {
		while( length( $line ) > $width ) {
			my $cut = $width - 1;
			push @lines, substr( $line, 0, $cut ) . $line_break;
			$line = substr( $line, $cut );
		}
		push @lines, $line;
	}

	# Return the line count as well if an array is requested
	if( wantarray ) {
		return( join( "\n", @lines ), scalar @lines );
	} else {
		return join( "\n", @lines );
	}
}

######################################################################
=pod

=item @changes = Self::myers_diff( $left: &[str], $right: &[str] )

This applies the Eugene Myers Diff Algorithm to the C<left> and C<right>
array refs of strings, returning an array of changes.

These changes are of the form:

 {
   operation => 'insert' | 'delete',
   change_start => <int>, # Where the change starts on the relevant side
   change_end => <int>,   # Where the change ends, so the change is @<left|right>[$change_start .. $change_end]
   left_idx => <int>,  # The left index, equal to 'change_start' for 'delete'
   right_idx => <int>, # The right index, equal to 'change_start' for 'insert'
 }

=cut
######################################################################

sub myers_diff
{
	my( $left_ref, $right_ref, $left_idx, $right_idx ) = @_;
	my @left = @{$left_ref};
	my @right = @{$right_ref};
	$left_idx = 0 unless $left_idx;
	$right_idx = 0 unless $right_idx;

	my $joint_len = @left + @right;
	my $array_len = 2 * min( scalar @left, scalar @right ) + 2;
	if( @left > 0 && @right > 0 ) {
		my @g = (0) x $array_len;
		my @p = (0) x $array_len;
		for my $h (0 .. (int($joint_len / 2) + $joint_len % 2)) {
			for my $r (0 .. 1) {
				my $m = $r ? -1 : 1;

				for( my $k = -($h - 2 * max(0, $h - @right)); $k <= $h - 2 * max(0, $h - @left); $k += 2 ) {
					my $left_offset;
					if( $k == -$h || ($k != $h && $g[($k - 1) % $array_len] < $g[($k + 1) % $array_len]) ) {
						$left_offset = $g[($k + 1) % $array_len];
					} else {
						$left_offset = $g[($k - 1) % $array_len] + 1;
					}
					my $right_offset = $left_offset - $k;
					my $s = $left_offset;
					my $t = $right_offset;
					while(
						$left_offset < @left &&
						$right_offset < @right &&
						$left[$r * (@left - 1) + $m * $left_offset] eq $right[$r * (@right - 1) + $m * $right_offset]
					) {
						$left_offset++;
						$right_offset++;
					}
					$g[$k % $array_len] = $left_offset;
					my $z = -$k + @left - @right;
					if(
						$joint_len % 2 == 1 - $r &&
						$z >= (1 - $h - $r) &&
						$z <= ($h + $r - 1) &&
						$g[$k % $array_len] + $p[$z % $array_len] >= scalar @left
					) {
						my $x = $r ? @left - $left_offset : $s;
						my $y = $r ? @right - $right_offset : $t;
						my $u = $r ? @left - $s : $left_offset;
						my $v = $r ? @right - $t : $right_offset;
						if( 2 * $h + $r > 2 || ( $x != $u && $y != $v ) ) {
							my @left_diff = myers_diff( [@left[0 .. $x - 1]], [@right[0 .. $y - 1]], $left_idx, $right_idx );
							my @right_diff = myers_diff( [@left[$u .. @left - 1]], [@right[$v .. @right - 1]], $left_idx + $u, $right_idx + $v );

							# Combine matching operations
							if( scalar @left_diff && scalar @right_diff && $left_diff[-1]->{operation} eq $right_diff[0]->{operation} ) {
								# Only combine operations if the end of one matches the start of the next
								if( $left_diff[-1]->{change_end} + 1 == $right_diff[0]->{change_start} ) {
									$left_diff[-1]->{change_end} = $right_diff[0]->{change_end};
									@right_diff = @right_diff[1 .. @right_diff - 1];
								}
							}

							return( @left_diff, @right_diff );
						} elsif ( @right > @left ) {
							return myers_diff( [], [@right[scalar @left .. scalar @right - 1]], $left_idx + @left, $right_idx + @left );
						} elsif ( @right < @left ) {
							return myers_diff( [@left[scalar @right .. scalar @left - 1]], [], $left_idx + @right, $right_idx + @right );
						} else {
							return ();
						}
					}
				}

				my @temp = @g;
				@g = @p;
				@p = @temp;
			}
		}
	} elsif( scalar @left > 0) {
		return( { operation => 'delete', change_start => $left_idx, change_end => $left_idx + @left - 1, left_idx => $left_idx, right_idx => $right_idx } );
	} elsif( scalar @right > 0) {
		return( { operation => 'insert', change_start => $right_idx, change_end => $right_idx + @right - 1, left_idx => $left_idx, right_idx => $right_idx } );
	} else {
		return ();
	}
}

sub action_create
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $subject_ds = $session->dataset( "subject" );
	my $subject = $self->{processor}->{dataobj};
	
	my $childid = $session->param( "childid" );
	return if !EPrints::Utils::is_set( $childid );

	if( $childid =~ /[^a-zA-Z0-9_\.\-]/ )
        {
		$self->{processor}->add_message( "error", $self->html_phrase( "invalid_subjectid", id => $session->xml->create_text_node( $childid ) ) );
		return;
        }

	my $child = $subject_ds->dataobj( $childid );
	if( defined $child )
	{
		$self->{processor}->add_message( "error", $self->html_phrase( "exists" ) );
		return;
	}

	# new subject node
	$child = $subject_ds->create_dataobj( {
		subjectid => $childid,
		parents => [ $subject->id ],
		depositable => 1 } );

	$self->{processor}->add_message( "message", $self->html_phrase( "added", newchild=>$child->render_value( "subjectid" ) ) );
	$self->{processor}->{dataobj} = $child;
}

sub action_link
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $subject_ds = $session->dataset( "subject" );
	my $subject = $self->{processor}->{dataobj};
	
	my $childid = $session->param( "childid" );
	return if !EPrints::Utils::is_set( $childid );

	my $child = $subject_ds->dataobj( $childid );

	if( grep { $_ eq $childid } @{$subject->get_value( "ancestors" )} )
	{
		$self->{processor}->add_message( "error", $self->html_phrase( "problem_ancestor" ) );
		return;
	}

	$child->set_value( "parents", [
		@{$child->value( "parents" )},
		$subject->id,
	]);
	$child->commit();

	$self->{processor}->add_message( "message", $self->html_phrase( "linked", newchild=>$child->render_description ) );
}

sub action_unlink
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $subject_ds = $repo->dataset( "subject" );
	my $subject = $self->{processor}->{dataobj};
	
	my $childid = $repo->param( "childid" );

	# already deleted?
	my $child = $subject_ds->dataobj( $childid );
	return if !defined $child;

	# already unlinked?
	return if !grep { $_ eq $subject->id } @{$child->value( "ancestors" )};

	# are we deleting?
	if( @{$child->value( "parents" )} < 2 )
	{
		my $idsuffix = EPrints::Utils::sanitise_element_id( $childid . "_unlink" );
		my $form = $self->render_form( $idsuffix );
		$form->appendChild( $repo->xhtml->hidden_field( childid => $childid, "childid_" . $idsuffix ) );
		$form->appendChild( $repo->render_action_buttons(
			remove => $repo->phrase( "lib/submissionform:action_remove" ),
			cancel => $repo->phrase( "lib/submissionform:action_cancel" ),
			_order => [qw( remove cancel )],
		) );
		$self->{processor}->add_message( "warning", $self->html_phrase( "confirm_form",
			form => $form,
			child => $child->render_description(),
		) );
		return;
	}

	$child->set_value( "parents", [
		grep { $_ ne $subject->id } @{$child->value( "parents" )}
		]);
	$child->commit;
	$self->{processor}->add_message( "message", $self->html_phrase( "unlinked" ) );
}

sub action_remove
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $subject_ds = $repo->dataset( "subject" );
	my $subject = $self->{processor}->{dataobj};
	my $childid = $repo->param( "childid" );
	
	my $child = $subject_ds->dataobj( $childid );

	# already removed?
	return if !defined $child;

	if ($child->remove())
	{
		$self->{processor}->add_message( "message", $self->html_phrase( "removed" ) );
	}
	else
	{
		$self->{processor}->add_message( "warning", $self->html_phrase( "has_child" ) );
	}
}

sub from
{
	my( $self ) = @_;


	if( defined $self->{processor}->{internal} )
	{
		$self->action_save;
		if( my $component = $self->current_component )
		{
			$component->update_from_form( $self->{processor} );
		}
		else
		{
			$self->workflow->update_from_form( $self->{processor}, undef, 1 );
		}
		$self->workflow->{item}->commit;
		$self->uncache_workflow;
		return;
	}

	$self->EPrints::Plugin::Screen::from;
}

sub hidden_bits
{
	my( $self ) = @_;

	# don't need dataset
	return(
		$self->EPrints::Plugin::Screen::hidden_bits,
		dataobj => $self->{processor}->{dataobj}->id,
	);
}

=back

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

