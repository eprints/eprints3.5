######################################################################
#
# EPrints::MetaField::Set
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Set> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

package EPrints::MetaField::Set;

use EPrints::MetaField::Text;
@ISA = EPrints::MetaField::Text;

use strict;

sub render_single_value
{
	my( $self, $session, $value ) = @_;

	return $self->render_option( $session , $value );
}

sub set_value
{
	my( $self, $object, $value ) = @_;

	if( $self->get_property( "multiple" ) && !$self->get_property( "sub_name" ) )
	{
		$value = [] if !defined $value;
		my %seen;
		@$value = grep {
			EPrints::Utils::is_set( $_ ) # multiple values must be defined
			&& !$seen{$_}++ # set values must be unique
		} @$value;
	}

	return $object->set_value_raw( $self->{name}, $value );
}

######################################################################
=pod

=item ( $options , $labels ) = $field->tags_and_labels( $session )

Return a reference to an array of options for this
field, plus an array of UTF-8 encoded labels for these options in the 
current language.

=cut
######################################################################

sub tags_and_labels
{
	my( $self , $session ) = @_;
	my @tags = $self->tags( $session );
	my %labels = ();
	foreach( @tags )
	{
		$labels{$_} = EPrints::Utils::tree_to_utf8( 
			$self->render_option( $session, $_ ) );
	}

        if( $self->get_property( 'order_labels' ) )
        {
                # Order the labels alphabetically
                my @otags = sort { $a ne 'other' && $b ne 'other' && ($labels{$a} cmp $labels{$b}) } @tags;
                return (\@otags, \%labels );
        }

	return (\@tags, \%labels);
}

sub tags
{
	my( $self, $session ) = @_;
	EPrints::abort( "no options in tags()" ) if( !defined $self->{options} );
	return @{$self->{options}};
}

######################################################################
=pod

=item $xhtml = $field->render_option( $session, $option )

Return the title of option $option in the language of $session as an 
XHTML DOM object.

=cut
######################################################################

sub render_option
{
	my( $self, $session, $option ) = @_;

	if( defined $self->get_property("render_option") )
	{
		return $self->call_property( "render_option", $session, $option );
	}

	$option = "" if !defined $option;

	my $phrasename = $self->{confid}."_fieldopt_".$self->{name}."_".$option;

	# if the option is empty, and no explicit phrase is defined, print 
	# UNDEFINED rather than an error phrase.
	if( $option eq "" && !$session->get_lang->has_phrase( $phrasename, $session ) )
	{
		$phrasename = "lib/metafield:unspecified";
	}

	return $session->html_phrase( $phrasename );
}


sub render_input_field_actual
{
	my( $self, $session, $value, $dataset, $staff, $hidden_fields, $obj, $basename, $one_field_component ) = @_;

	if( $self->get_property( "input_ordered" ) )
	{
		return $self->SUPER::render_input_field_actual( 
			$session, $value, $dataset, $staff, $hidden_fields, $obj, $basename, $one_field_component );
	}

	my $required = $self->get_property( "required" );

	my %settings;
	my $default = $value;
	$default = [ $value ] unless( $self->get_property( "multiple" ) );
	$default = [] if( !defined $value );

	# called as a separate function because subject does this
	# bit differently, and overrides render_set_input.
	return $self->render_set_input( $session, $default, $required, $obj, $basename, $one_field_component );
}

sub input_tags_and_labels
{
	my( $self, $session, $obj ) = @_;

	my @tags = $self->tags( $session );
	if( defined $self->get_property("input_tags") )
	{
		@tags = $self->call_property( "input_tags", $session, $obj );
	}

	return $self->tags_and_labels( $session );
}

# this is only called by the compound renderer
sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

	my( $tags, $labels ) = $self->input_tags_and_labels( $session, $obj );

	# If it's not multiple and not required there 
	# must be a way to unselect it.
	$tags = [ "", @{$tags} ];
	my $unspec = EPrints::Utils::tree_to_utf8( $self->render_option( $session, undef ) );
	$labels = { ""=>$unspec, %{$labels} };

	my @classes;
	push @classes, join('_', 'ep', $self->{dataset}->base_id, $self->name);
	push @classes, join('_', 'eptype', $self->{dataset}->base_id, $self->type);

	my $readonly = ( $self->{readonly} && $self->{readonly} eq "1") ? 1 : undef;
 	push @classes, "ep_readonly" if $readonly;
 	
 	# needs to set the selectedIndex back to the original value to enforce readonly
 	my $default_index = 0;
 	foreach my $t ( @{$tags} )
 	{
 	        last if defined $value && $t eq $value;
 	        $default_index++;
	}

	return( [ [ { el=>$session->render_option_list(
			values => $tags,
			labels => $labels,
			name => $basename,
			class => join(" ", @classes),
			readonly => $readonly,
			id => $basename,
			default => $value,
			multiple => 0,
			height => 1,
			'aria-labelledby' => $self->get_labelledby( $basename ),
			'aria-describedby' => $self->get_describedby( $basename, $one_field_component ),
	) } ]] );
}

# basic input renderer for "set" type fields
sub render_set_input
{
	my( $self, $session, $default, $required, $obj, $basename, $one_field_component ) = @_;

	my( $tags, $labels ) = $self->input_tags_and_labels( $session, $obj );
	
	my $input_style = $self->get_property( "input_style" );

	my @classes;
	push @classes, join('_', 'ep', $self->{dataset}->base_id, $self->name);
	push @classes, join('_', 'eptype', $self->{dataset}->base_id, $self->type);
	push @classes, join('_', 'eptype', $self->{dataset}->base_id, $self->type, $input_style) if $input_style;
	
	my $readonly = $self->{readonly} && ( $self->{readonly} eq "1" || $self->{readonly} eq "yes" ) ? 1 : undef; # sorry
 	push @classes, "ep_readonly" if $readonly;

	if( 
		!$self->get_property( "multiple" ) && 
		!$required ) 
	{
		# If it's not multiple and not required there 
		# must be a way to unselect it.
		$tags = [ "", @{$tags} ];
		my $unspec = EPrints::Utils::tree_to_utf8( $self->render_option( $session, undef ) );
		$labels = { ""=>$unspec, %{$labels} };
	}

	if( $input_style eq "short" )
	{
		my $legend = undef;
		if ( $self->{form_input_style} eq "checkbox" )
		{
                	$legend = $session->make_text( EPrints::Utils::tree_to_utf8( $self->render_name( $self->{session} ) ) . EPrints::Utils::tree_to_utf8( $session->html_phrase( "lib/metafield/set:legend_suffix" ) ) );
		}
		return( $session->render_option_list(
				checkbox => ($self->{form_input_style} eq "checkbox" ?1:0),
				legend => $legend,		
				values => $tags,
				labels => $labels,
				name => $basename,
				class => join(" ", @classes),
				id => $basename,
				readonly => $readonly,
				default => $default,
				multiple => $self->{multiple},
				height => $self->{input_rows},
				'aria-labelledby' => $self->get_labelledby( $basename ),
				'aria-describedby' => $self->get_describedby( $basename, $one_field_component ) ) );
	}

	my( $fieldset, $list );

	if( $input_style eq "long" || $input_style eq "medium" )
	{
		$list = $session->make_element( "dl", class=>"form-control m-0 ep_field_set_" . $input_style );
	}	
	else
	{
		$list = $session->make_element( "fieldset", class=>"ep_option_list" );
		my $legend = $session->make_element( "legend", id=> $basename."_label", class=>"ep_field_legend", "aria-labelledby" => $basename."_legend_label" );
	        my $legendtext = $session->make_text( EPrints::Utils::tree_to_utf8( $self->render_name( $self->{session} ) ) . EPrints::Utils::tree_to_utf8( $session->html_phrase( "lib/metafield/set:legend_suffix" ) ) );
        	if( $self->{required} )
	        {
        	        $legend->appendChild( $session->html_phrase(
                	        "sys:ep_form_required",
                        	 label=>$legendtext ) );
	        }
        	else {
         	       $legend->appendChild( $legendtext );
        	}
		$list->appendChild( $legend );
	}
	foreach my $opt ( @{$tags} )
	{
		# "group" set options under headings
                my $phraseid = $self->{confid}."_optheading_".$self->{name}."_".$opt;
                if( $session->get_lang->has_phrase( $phraseid ) )
                {
                        my $div = $session->make_element( "div", class => "ep_optheading" );
                        $div->appendChild( $session->html_phrase( $phraseid ) );
                        $list->appendChild( $div );
                }

		my $row;
		if( $input_style eq "long" || $input_style eq "medium" )
		{
			$row = $session->make_element( "dt", class => "d-inline", id => $basename."_".$opt."_title" );
        	        my $checked = undef;
                	my $type = "radio";
	                if( $self->{multiple} )
        	        {
                	        $type = "checkbox";
                        	foreach( @{$default} )
	                        {
        	                        $checked = "checked" if( $_ eq $opt );
                	        }
	                }
        	        else
	                {
        	                $type = "radio";
                	        if( defined $default->[0] && $default->[0] eq $opt )
                        	{
	                                $checked = "checked";
        	                }
                	}
			my $dd;
			if ( $input_style eq "long" )
			{
		                $row->appendChild( $session->render_noenter_input_field(
        		                type => $type,
                		        name => $basename,
                        		id => $basename."_".$opt,
	                        	value => $opt,
	        	                class => join(" ", @classes),
        	        	        checked => $checked,
					'aria-labelledby' => $basename."_".$opt."_title",
					'aria-describedby' => $basename."_".$opt."_desc",
				) );
	                	$row->appendChild( $session->make_text( " ".$labels->{$opt} ));
        	        	$dd = $session->make_element( "dd", class => "d-inline", id=>$basename."_".$opt."_desc" );
                		my $phrasename = $self->{confid}."_optdetails_".$self->{name}."_".$opt;
                		$dd->appendChild( $session->html_phrase( $phrasename ));
			}
			else 
			{
				$row->appendChild( $session->render_noenter_input_field(
	                                type => $type,
        	                        name => $basename,
					title => $labels->{$opt},
                	                id => $basename."_".$opt,
                        	        value => $opt,
                                	class => join(" ", @classes),
	                                checked => $checked,
        	                        'aria-labelledby' => $basename."_".$opt."_title",
                	        ) );
	                        $dd = $session->make_element( "dd", class => "d-inline", id=>$basename."_".$opt."_label", 'aria-describedby'=>$self->get_labelledby( $basename ) );
				$dd->appendChild( $session->make_text( " ".$labels->{$opt} ) );
			}
			$list->appendChild( $row );
                        $list->appendChild( $dd );
			$list->appendChild( $session->make_element( "br" ) );
		}
		else
		{
			$row = $session->make_element( "div" );
			my $label = $session->make_element( "label", for=>$basename."_".$opt );
	                $row->appendChild( $label );
        	        my $checked = undef;
                	my $type = "radio";
                	if( $self->{multiple} )
                	{
                        	$type = "checkbox";
	                        foreach( @{$default} )
        	                {
                	                $checked = "checked" if( $_ eq $opt );
                        	}
	                }
        	        else
                	{
                        	$type = "radio";
 	                       if( defined $default->[0] && $default->[0] eq $opt )
        	                {
                	                $checked = "checked";
                        	}
                	}
			my @basename_bits = split( "_", $basename );
			splice(@basename_bits, 1, 0, ('help') );
	                my $describedby = join( "_", @basename_bits );	
               		$label->appendChild( $session->render_noenter_input_field(
                        	type => $type,
	                        name => $basename,
        	                id => $basename."_".$opt,
                	        value => $opt,
                        	class => join(" ", @classes),
	                        checked => $checked,
				'aria-labelledby' => $self->get_labelledby( $basename ),
				'aria-describedby' => $self->get_describedby( $basename, $one_field_component ) ) );
        	        $label->appendChild( $session->make_text( " ".$labels->{$opt} ));
                	$list->appendChild( $row );
		}
	}
	return $fieldset if defined $fieldset;
	return $list;
}

sub form_value_actual
{
	my( $self, $session, $obj, $basename ) = @_;

	if( $self->get_property( "input_ordered" ) )
	{
		return $self->SUPER::form_value_actual( $session, $obj, $basename );
	}

	my @values = grep {
		$_ ne "-" # for the  ------- in defaults at top
	} $session->param( $basename );

	return $self->get_property( "multiple" ) ? \@values : $values[0];
}

# the ordering for set is NOT the same as for normal
# fields.
sub get_values
{
	my( $self, $session, $dataset, %opts ) = @_;

	my @tags = $self->tags( $session );

	return \@tags;
}

sub get_value_label
{
	my( $self, $session, $value ) = @_;
		
	return $self->render_option( $session, $value );
}

sub ordervalue_basic
{
	my( $self , $value , $session , $langid ) = @_;

	return "" unless( EPrints::Utils::is_set( $value ) );

	my $label = $self->get_value_label( $session, $value );
	return EPrints::Utils::tree_to_utf8( $label );
}

sub split_search_value
{
	my( $self, $session, $value ) = @_;

	return $self->EPrints::MetaField::split_search_value( $session, $value );
}

sub render_search_input
{
	my( $self, $session, $searchfield, %opts ) = @_;

	if( defined $self->{render_search_input} )
	{
		return $self->call_property( "render_search_input", $self, $session, $searchfield );
	}

	my $frag = $session->make_doc_fragment;
	
	$frag->appendChild( $self->render_search_set_input( 
				$session,
				$searchfield,
				%opts  ) );

	if( $self->get_property( "multiple" ) )
	{
		my @set_tags = ( "ANY", "ALL" );
		my %set_labels = ( 
			"ANY" => $session->phrase( "lib/searchfield:set_any" ),
			"ALL" => $session->phrase( "lib/searchfield:set_all" ) );


		$frag->appendChild( $session->make_text(" ") );
		$frag->appendChild( 
			$session->render_option_list(
				name=>$searchfield->get_form_prefix."_merge",
				values=>\@set_tags,
				default=>$searchfield->get_merge,
				labels=>\%set_labels,
				'aria-labelledby'=>$searchfield->get_form_prefix."_label" ) );
	}
	if( $searchfield->get_match ne $self->property( "match" ) )
	{
		$frag->appendChild(
			$session->render_hidden_field(
				$searchfield->get_form_prefix . "_match",
				$searchfield->get_match
			) );
	}

	return $frag;
}

sub render_search_set_input
{
	my( $self, $session, $searchfield, %opts ) = @_;

	my $prefix = $searchfield->get_form_prefix;
	my $value = $searchfield->get_value;

	my( $tags, $labels ) = ( [], {} );
	# find all the fields we're searching to get their options
	# too if we need to!
	my @allfields = @{$searchfield->get_fields};
	if( scalar @allfields == 1 )
	{
		( $tags, $labels ) = $self->tags_and_labels( $session );
	}
	else
	{
		my( $t ) = {};
		foreach my $field ( @allfields )
		{
			my ( $t2, $l2 ) = $field->tags_and_labels( $session );
			foreach( @{$t2} ) { $t->{$_}=1; }
			foreach( keys %{$l2} ) { $labels->{$_}=$l2->{$_}; }
		}
		my @tags = keys %{$t};
		$tags = \@tags;
	}

	my $max_rows =  $self->get_property( "search_rows" );

	my $height = scalar @$tags;
	$height = $max_rows if( $height > $max_rows );

	my @defaults = ();;
	# Do we have any values already?
	if( defined $value && $value ne "" )
	{
		@defaults = split /\s/, $value;
	}

	return $session->render_option_list( 
		checkbox => ($self->{search_input_style} eq "checkbox"?1:0),
		name => $prefix,
		legend => $opts{legend}, 
		default => \@defaults,
		multiple => 1,
		labels => $labels,
		values => $tags,
		height => $height,
		'aria-labelledby' => $prefix . "_label" );
}	

sub from_search_form
{
	my( $self, $session, $prefix ) = @_;

	my @vals = ();
	foreach( $session->param( $prefix ) )
	{
		next if m/^\s*$/;
		# ignore the "--------" divider.
		next if m/^-$/;
		push @vals,$_;
	}
		
	# We have some values. Join them together.
	my $val = join ' ', @vals;
	$val = undef if $val eq '';

	return(
		$val,
		scalar($session->param( $prefix."_match" )),
		scalar($session->param( $prefix."_merge" ))
	);
}

	
sub render_search_description
{
	my( $self, $session, $sfname, $value, $merge, $match ) = @_;

	my $phraseid;
	if( $merge eq "ANY" )
	{
		$phraseid = "lib/searchfield:desc_any_in";
	}
	else
	{
		$phraseid = "lib/searchfield:desc_all_in";
	}

	my $valuedesc = $session->make_doc_fragment;
	my $max_to_show = $self->get_property( "render_max_search_values" );
	my @list = split( ' ',  $value );
	for( my $i=0; $i<scalar @list; ++$i )
	{
		if( $max_to_show && $i == $max_to_show )
		{
			$valuedesc->appendChild( $session->html_phrase( "lib/searchfield:n_more_values", 
				n => $session->xml->create_text_node( scalar @list - $i ),
				total => $session->xml->create_text_node( scalar @list ) ) );
			last;
		}
		if( $i>0 )
		{
			$valuedesc->appendChild( $session->make_text( ", " ) );
		}
		
		$valuedesc->appendChild( $session->make_text( '"' ) );
		$valuedesc->appendChild(
			$self->get_value_label( $session, $list[$i] ) );
		$valuedesc->appendChild( $session->make_text( '"' ) );
	}

	return $session->html_phrase(
		$phraseid,
		name => $sfname, 
		value => $valuedesc ); 
}

sub get_search_conditions_not_ex
{
	my( $self, $session, $dataset, $search_value, $match, $merge,
		$search_mode ) = @_;
	
	return EPrints::Search::Condition->new( 
		'=', 
		$dataset,
		$self, 
		$search_value );
}

sub get_search_group { return 'set'; }

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{input_style} = "short";
	$defaults{search_input_style} = "checkbox";
	$defaults{form_input_style} = "select";
	$defaults{input_rows} = $EPrints::MetaField::FROM_CONFIG;
	$defaults{input_ordered} = 0;
	$defaults{search_rows} = $EPrints::MetaField::FROM_CONFIG;
	$defaults{options} = $EPrints::MetaField::REQUIRED;
	$defaults{input_tags} = $EPrints::MetaField::UNDEF;
	$defaults{render_option} = $EPrints::MetaField::UNDEF;
	$defaults{render_max_search_values} = 5;
	$defaults{sql_index} = 1;
	$defaults{match} = "EQ";
	$defaults{merge} = "ANY";
	$defaults{order_labels} = 0;
	return %defaults;
}

sub get_xml_schema_type
{
	my( $self ) = @_;

	return $self->get_xml_schema_field_type;
}

sub render_xml_schema_type
{
	my( $self, $session ) = @_;

	my $type = $session->make_element( "xs:simpleType", name => $self->get_xml_schema_type );

	my( $tags, $labels ) = $self->tags_and_labels( $session );

	my $restriction = $session->make_element( "xs:restriction", base => "xs:string" );
	$type->appendChild( $restriction );
	foreach my $value (@$tags)
	{
		my $enumeration = $session->make_element( "xs:enumeration", value => $value );
		$restriction->appendChild( $enumeration );
		if( defined $labels->{$value} )
		{
			my $annotation = $session->make_element( "xs:annotation" );
			$enumeration->appendChild( $annotation );
			my $documentation = $session->make_element( "xs:documentation" );
			$annotation->appendChild( $documentation );
			$documentation->appendChild( $session->make_text( $labels->{$value} ) );
		}
	}

	return $type;
}

######################################################################
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

