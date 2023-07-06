# Template.pm

package EPrints::Template;

use strict;
use warnings;

sub template_phrase
{
	my( $repository, $phrase, $variables, %params ) = @_;

	my( $template, $fb ) = $repository->get_language->_get_phrase( $phrase );

	my $helper_functions = {

		"epv:form" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $form = $params{session}->render_form( $node->getAttribute( 'method' ), $node->getAttribute( 'action' ) );

			EPrints::XML::EPC::expand_attributes( $form, %params );

 			if( $node->hasChildNodes )
			{
				$form->appendChild( &{$process_child_nodes_func}( $node, %params ) );
			}

			return $form;
		},

		"epv:link" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $link = $params{session}->render_link( $node->getAttribute( 'uri' ), $node->getAttribute( 'target' ) );

			EPrints::XML::EPC::expand_attributes( $link, %params );

 			if( $node->hasChildNodes )
			{
				$link->appendChild( &{$process_child_nodes_func}( $node, %params ) );
			}

			return $link;
		},

		"epv:render_row" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $children = &{$process_child_nodes_func}( $node, %params );

			my @elements;

			foreach my $element ( $children->getChildNodes )
			{
				push @elements, $element;
			}

			return $repository->render_row( @elements );
		},

		"epv:render_row_with_help" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my %options;

			foreach my $attr ( $node->getAttributes )
			{
				$options{$attr->nodeName} = EPrints::XML::EPC::expand_attribute( $attr->nodeValue, $attr->nodeName, \%params );
			}

			foreach my $child ( $node->getChildNodes )
			{
				if( EPrints::XML::is_dom( $child, "Element" ) && ( $child->tagName eq "epv:label" ) )
				{
					$options{label} = &{$process_child_nodes_func}( $child, %params );
				}

				if( EPrints::XML::is_dom( $child, "Element" ) && ( $child->tagName eq "epv:field" ) )
				{
					$options{field} = &{$process_child_nodes_func}( $child, %params );
				}

				if( EPrints::XML::is_dom( $child, "Element" ) && ( $child->tagName eq "epv:help" ) )
				{
					$options{help} = &{$process_child_nodes_func}( $child, %params );
				}
			}

			return $repository->render_row_with_help( %options );
		},

		"epv:button" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my %attributes;

			foreach my $attr ( $node->getAttributes )
			{
				$attributes{$attr->nodeName} = $attr->nodeValue;
			}

			my $button = $params{session}->render_button( %attributes );

			EPrints::XML::EPC::expand_attributes( $button, %params );

 			if( $node->hasChildNodes )
			{
				$button->appendChild( &{$process_child_nodes_func}( $node, %params ) );
			}

			return $button;
		},

		"epv:render_single_option" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $key = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'key' ), 'key', \%params );
			my $selected = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'selected' ), 'selected', \%params );

			my $desc = &{$process_child_nodes_func}( $node, %params );

			return $params{session}->render_single_option($key, $desc, $selected);
		},

		"epv:render_hidden_field" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $name = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'name' ), 'name', \%params );
			my $value = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'value' ), 'value', \%params );

			return $params{session}->render_hidden_field($name, $value);
		},

		"epv:render_input_field" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my %options;
			my $checked = 0;

			foreach my $attr ( $node->getAttributes )
			{
				my $name = $attr->nodeName;
				my $value = $attr->nodeValue;

				if( $name eq "checked" )
				{
					if( EPrints::XML::EPC::expand_attribute( $value, $name, \%params ) )
					{
						$checked = 1;
					}
				}
				elsif( $name eq "opts" )
				{
					my $opts = EPrints::Script::execute( $node->getAttribute( 'opts' ), \%params )->[0];

					foreach my $opt_key ( keys $opts )
					{
						$options{$opt_key} = $opts->{$opt_key};
					}
				}
				elsif( $name eq "onchange" )
				{
					my $expanded_attribute = EPrints::XML::EPC::expand_attribute( $value, $name, \%params );

					if( $expanded_attribute ne "" )
					{

						$options{$name} = $expanded_attribute;
					}
				}
				else
				{
					$options{$name} = EPrints::XML::EPC::expand_attribute( $value, $name, \%params );
				}
			}

			my $result = $params{session}->render_input_field( %options );

			if( $checked )
			{
				$result->setAttribute( "checked", "checked" );
			}

			return $result;
		},

		"epv:render_message" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $type = $node->getAttribute( 'type' );
			my $show_icon = $node->getAttribute( 'showicon' );

			my $content = &{$process_child_nodes_func}( $node, %params );

			return $params{session}->render_message($type, $content, $show_icon);
		},

		"epv:box" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my %options;

			foreach my $attr ( $node->getAttributes )
			{
				$options{$attr->nodeName} = EPrints::XML::EPC::expand_attribute( $attr->nodeValue, $attr->nodeName, \%params );
			}

			$options{title} = $params{session}->make_doc_fragment;
			$options{content} = $params{session}->make_doc_fragment;
			$options{session} = $params{session};

			foreach my $child ( $node->getChildNodes )
			{
				if( EPrints::XML::is_dom( $child, "Element" ) && ( $child->tagName eq "epv:title" ) )
				{
					$options{title}->appendChild( &{$process_child_nodes_func}( $child, %params ) );
				}

				if( EPrints::XML::is_dom( $child, "Element" ) && ( $child->tagName eq "epv:content" ) )
				{
					$options{content}->appendChild( &{$process_child_nodes_func}( $child, %params ) );
				}
			}

			my $box = EPrints::Box::render( %options );

			EPrints::XML::EPC::expand_attributes( $box, %params );

			return $box;
		},

		"epv:tabs" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;
	
			$params{current_tabs} = {
				index => 0,
				labels => [],
				contents => [],
				options => {},
			};

			foreach my $attr ( $node->getAttributes )
			{
				my $attr_name = $attr->nodeName;
				my $attr_value = EPrints::XML::EPC::expand_attribute( $attr->nodeValue, $attr_name, \%params );

				if( List::Util::first { $_ eq $attr_name } qw( basename current base_url ) )
				{
					$params{current_tabs}->{options}->{$attr_name} = $attr_value;
				}
			}

			&{$process_child_nodes_func}( $node, %params );

			return $params{session}->xhtml->tabs(
				$params{current_tabs}->{labels},
				$params{current_tabs}->{contents},
				%{$params{current_tabs}->{options}}
			);
		},

		"epv:tab" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $has_label = 0;
			my $tab_index = $params{current_tabs}->{index};

			foreach my $attr ( $node->getAttributes )
			{
				my $attr_name = $attr->nodeName;
				my $attr_value = EPrints::XML::EPC::expand_attribute( $attr->nodeValue, $attr_name, \%params );

				if( $attr_name eq "label" )
				{
					push $params{current_tabs}->{labels}, EPrints::XML::EPC::expand_attribute( $attr_value, $attr_name, \%params );
					$has_label = 1;
				}
				elsif( $attr_name eq "expensive" )
				{
					if( !defined $params{current_tabs}->{options}->{expensive} )
					{
						$params{current_tabs}->{options}->{expensive} = [];
					}

					if( $attr_value eq "yes" )
					{
						push $params{current_tabs}->{options}->{expensive}, $tab_index;
					}
				}
				elsif( $attr_name eq "alias" )
				{
					if( !defined $params{current_tabs}->{options}->{aliases} )
					{
						$params{current_tabs}->{options}->{aliases} = {};
					}

					$params{current_tabs}->{options}->{aliases}->{$tab_index} = $attr_value;
				}
				elsif( $attr_name eq "link" )
				{
					if( !defined $params{current_tabs}->{options}->{links} )
					{
						$params{current_tabs}->{options}->{links} = {};
					}

					$params{current_tabs}->{options}->{links}->{$tab_index} = $attr_value;
				}
			}

			if( $has_label == 0 )
			{
				EPrints::abort( "Tab is missing a label." );	
			}

			$params{current_tabs}->{contents}->[$tab_index] = &{$process_child_nodes_func}( $node, %params );
 
 			$params{current_tabs}->{index}++;

			return undef;
		},

		"epv:create_data_element" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $tag = $node->getAttribute( 'tag' );
			my $expr = $node->getAttribute( 'expr' );

			my $data;

			if( defined( $expr ) )
			{
				$data = EPrints::Script::execute( $expr, \%params )->[0];
			}
			else
			{
				if( $node->hasChildNodes )
				{
					$data = &{$process_child_nodes_func}( $node, %params );
				}
			}

			my %passed_attrs;

			foreach my $attr ( $node->getAttributes )
			{
				my $name = $attr->nodeName;
				my $value = $attr->nodeValue;

				next if $name eq "tag";
				next if $name eq "expr";

				$passed_attrs{$name} = EPrints::XML::EPC::expand_attribute( $value, $name, \%params );
			}

			return $params{session}->xml->create_data_element( $tag, $data, %passed_attrs );
		},

		"epv:link_problem_xhtml" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			my $screen_id = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'screenid' ), 'screenid', \%params );
			my $class = EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'class' ), 'class', \%params );

			my $new_stage = EPrints::Script::execute( $node->getAttribute( 'newstage' ), \%params )->[0];

			my $content = &{$process_child_nodes_func}( $node, %params );

			unless ((ref $content) =~ /^XML/)
			{
				$content = $content->[0];
			}

			$params{workflow}->link_problem_xhtml( $content, $screen_id, $new_stage, $class );

			return $content;
		},

		"epv:render_option_list" => sub {

			my( $node, $process_child_nodes_func, %params ) = @_;

			# TODO

			# params:
			#   height
			#   multiple
			#   pairs
			#   legend
			#   checkbox
			#   defaults_at_top
			#   class

			return $params{session}->render_option_list(
				'name' => EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'name' ), 'name', \%params ),
				'default' => EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'default' ), 'default', \%params ),
				'aria-labelledby' => EPrints::XML::EPC::expand_attribute( $node->getAttribute( 'aria-labelledby' ), 'aria-labelledby', \%params ),
				'values' => EPrints::Script::execute( $node->getAttribute( 'values' ), \%params )->[0],
				'labels' => EPrints::Script::execute( $node->getAttribute( 'labels' ), \%params )->[0],
			);
		},
	};

	my $template_result = EPrints::XML::EPC::process( $template, %$variables,
		session => $repository, helper_functions => $helper_functions, strip_empty_text_nodes => 1 );

	if( $params{single} )
	{
		if( !$template_result->hasChildNodes )
		{
			EPrints::abort( "Template $phrase has no nodes." );
		}

		return $template_result->childNodes->[0]->cloneNode(1);
	}

	my $document_fragment = $repository->xml->create_document_fragment;

	foreach my $element ($template_result->getChildNodes)
	{
		$document_fragment->appendChild( $element );

		# if( $element->isa( 'XML::LibXML::Element' ))
		# {
		# 	$element->setAttribute( 'ep-phrase', $phrase );
		# }
	}

	return $document_fragment;
}

1;



=head1 COPYRIGHT

=for COPYRIGHT BEGIN

Copyright 2020 University of Southampton.
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

