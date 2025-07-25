=head1 NAME

EPrints::Plugin::Screen::Subject::Edit

=head1 METHODS

=cut


package EPrints::Plugin::Screen::Subject::Edit;

use EPrints::Plugin::Screen::Workflow::Edit;
@ISA = qw( EPrints::Plugin::Screen::Workflow::Edit );

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

	$processor->{tab_prefix} = 'ep_subject_edit';

	$processor->{dataset} = $self->{session}->dataset( "subject" );

	my $id = $self->{session}->param( "dataobj" );
	if( !EPrints::Utils::is_set( $id ) )
	{
		$processor->{dataobj} = $processor->{dataset}->dataobj( "ROOT" );
	}

	$self->SUPER::properties_from;
}

sub wishes_to_export { shift->{repository}->param( 'ajax' ) }

sub export_mime_type { 'text/html;charset=utf-8' }

sub export
{
	my( $self ) = @_;

	my $id_prefix = $self->{processor}->{tab_prefix};

	my $current = $self->{session}->param( "${id_prefix}_current" );
	$current = 0 if !defined $current;

	# The first tab is loaded from a stage not a screen
	return if $current == 0;

	my @screens;
	foreach my $item ( $self->list_items( 'subject_edit_tabs', filter => 0 ) )
	{
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );
		push @screens, $item->{screen};
	}

	local $self->{processor}->{current} = $current;

	my $content = $screens[$current - 1]->render();
	binmode(STDOUT, ":utf8");
	print $self->{repository}->xhtml->to_xhtml( $content );
	$self->{repository}->xml->dispose( $content );
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

	my $current = $session->param( $processor->{tab_prefix} . '_current' );
	$current = 0 if !defined $current;

	my @labels = ( $session->phrase( 'Plugin/Screen/Subject/Edit:title' ) );
	my @contents = ( $stage->render( $session, $workflow ) );
	my @expensive;
	for my $item ($self->list_items( 'subject_edit_tabs', filter => 0 )) {
		next if !($item->{screen}->can_be_viewed & $self->who_filter);
		next if $item->{action} && !$item->{screen}->allow_action( $item->{action} );

		# allow hidden_bits to point to the correct tab for local links
		local $self->{processor}->{current} = scalar @contents;

		my $screen = $item->{screen};
		push @labels, $screen->render_tab_title;
		push @expensive, scalar @contents if $screen->{expensive};

		if( $screen->{expensive} && $current != scalar @contents ) {
			push @contents, $session->html_phrase( 'cgi/users/edit_eprint:loading' );
		} else {
			push @contents, $screen->render( $processor->{tab_prefix} . '_' . scalar @contents );
		}
	}

	$form->appendChild( $session->xhtml->tabs(
		\@labels,
		\@contents,
		basename => $processor->{tab_prefix},
		current => $current,
		expensive => \@expensive,
	) );

	$form->appendChild( $session->render_hidden_field( "_default_action", "register" ) );
	$form->appendChild( $session->render_action_buttons(
		save => $self->phrase( "action_save" )
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
		depositable => 'TRUE' } );

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
		$self->{processor}->{tab_prefix} . "_current" => $self->{processor}->{current},
	);
}

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

