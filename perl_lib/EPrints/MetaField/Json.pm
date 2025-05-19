######################################################################
#
# EPrints::MetaField::Json;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Json> - a compound which stores a number of fields in a JSON object

=head1 DESCRIPTION

Like a Compound field, this field is designed to have a number of subfields which are all stored and displayed under the same parent field. However, unlike the Compound field, instead of storing each one in its own field or table, we store all the subfields in a single database field as a JSON string.

=head2 Usage
The field works by providing a (required) C<json_config> parameter, for example:
 {
	name => "fieldname",
	type => "json",
	json_config => [
		{
			name => "subfield1",
			type => "text"
		},
		{
			name => "subfield2",
			type => "number"
		},
		{
			name => "subfield3",
			type => "richtext"
		},
		{
			name => "subfield4",
			type => "namedset"
			set_name => "example_set"
		}
	],
 }

=head2 Field types

For the subfield type, the following fields are currently compatible:

=over 4

=item B<text> - A single line text field (i.e. <input type="text">)

=item B<number> - A numerical text field (i.e. <input type="number">)

=item B<longtext> - A multi-line text field (i.e. <textarea>)

=item B<boolean> - A checkbox field (i.e. <input type="checkbox">)

=item B<richtext> - A multi-line text field with a WYSIWYG editor (requires the C<richtext> ingredient)

=item B<namedset> - A set of options (i.e. <select>), expects a C<set_name> parameter

=back

These all render as their standard EPrints counterparts would, however are rendered by JavaScript instead of the standard EPrints form renderer.

The corresponding phrases for each subfield are in the format:

=over 4

=item C<eprint_fieldname_${fieldname}_${subfieldname}>

=item C<eprint_fieldhelp_${fieldname}_${subfieldname}>

=back

The same convention is used for the C<ep_eprint> classes added to inputs

=head2 Table view

The JSON field can also be used to render a table, with a fixed number of rows. In this scenario, the JSON string stored is a JSON array.

Use C<render_table> to turn on the table mode, and C<table_row_count> to specify the number of rows. If you want the user to be able to add rows you should set C<table_dynamic_row_count> to 1.

In some tables, you may want to skip certain subfields - e.g. the third row doesn't have subfield 3. If the value of the subfield is C<__json_field_control__skip>, the subfield will not render.

If you set C<table_allow_hide_rows> to be true, you get a select to select which rows you want to appear and which not. C<table_show_hide_rows> default is true. This will show the selector. Allows you to hide on some views, e.g. allowing certain workflows to determine rows shown, and certain to edit values

If you set C<table_hide_table> to be true, the table is hidden, e.g. allowing certain workflows to determine rows shown, and certain to edit values

If you set C<table_hide_rows_render_js>, you can provide custom JS to render the hide rows selector and how the json is updated.

## List view
The JSON field can also be used to display the fields in multiple columns, instead of the standard one-after-the-other. This is helpful in scenarios where you have lots of small fields, e.g. a series of boolean checkboxes.

Use C<display_as_list> to turn on the list mode, and C<display_as_list_cols> to specify the number of columns you want (defaults to 2).

=head2 Other parameters

You can also specify the following:

=over 4

=item C<richtext_init_fun> - determines the function which initialises the TinyMCE richtext field. Default is C<initTinyMCE>, as defined in C<98_richtext.js>

=item C<richtext_init_fun_readonly> - determines the function which initialises the TinyMCE richtext field when readonly is true. Default is C<initTinyMCEReadOnly>, as defined in C<98_richtext.js>

=item C<readonly> - set all fields readonly

=item C<readonly_fields> - string of (space separated) fields you want to be readonly

=item C<hidden_fields> - string of (space separated) fields you want to be hidden

=back

=head2 Lookup

You can provide an C<input_lookup_url> as per standard MetaFields.

When added, each subfield will have lookup capabilities. It will send the following as parameters to the C<input_lookup_url>:

=over 4

=item C<q> - the query

=item C<field> - the json field name

=item C<json_field> - the subfield name, per the json_config

=back

A basic CGI script that accepts these parameters and uses them to lookup on a particular subfield is provided.

=cut

package EPrints::MetaField::Json;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;
use EPrints::Const qw( :metafield );
use JSON;
use List::Util qw( any );
use Try::Tiny;

# Taken from MetaField.pm, altered to add in JavaScript after the element is rendered (changes commented)
# The main textarea here will be hidden in the UI, but will be used by the added JavaScript to store the up-to-date JSON object
sub render_input_field_actual
{
	my( $self, $session, $value, $dataset, $staff, $hidden_fields, $obj, $basename ) = @_;

	# Note: if there is only one element we still need the table to
	# centre-align the input

	my $elements = $self->get_input_elements( $session, $value, $staff, $obj, $basename );

	my $frag = $session->make_doc_fragment;

	my $table = $session->make_element( "div", class=>"ep_form_input_grid" );
	$frag->appendChild ($table);

	my $col_titles = $self->get_input_col_titles( $session, $staff );
	if( defined $col_titles )
	{
		my $tr = $session->make_element( "div" );
		my $th;
		my $x = 0;
		if( $self->get_property( "multiple" ) && $self->{input_ordered})
		{
			$th = $session->make_element( "div", class=>"empty_heading", id=>$basename."_th_".$x++ );
			$tr->appendChild( $th );
		}

		if( !defined $col_titles )
		{
			$th = $session->make_element( "div", class=>"empty_heading", id=>$basename."_th_".$x++ );
			$tr->appendChild( $th );
		}
		else
		{
			my @input_ids = $self->get_basic_input_ids( $session, $basename, $staff );
			foreach my $col_title ( @{$col_titles} )
			{
				$th = $session->make_element( "div", class=>"heading", id=>$input_ids[$x++]."_label" );
				$th->appendChild( $col_title );
				$tr->appendChild( $th );
			}
		}
		$table->appendChild( $tr );
	}

	my $y = 0;
	foreach my $row ( @{$elements} )
	{
		my $x = 0;
		my $tr = $session->make_element( "div" );
		foreach my $item ( @{$row} )
		{
			my %opts = ( id=>$basename."_cell_".$x++."_".$y );
			foreach my $prop ( keys %{$item} )
			{
				next if( $prop eq "el" );
				$opts{$prop} = $item->{$prop};
			}
			my $td = $session->make_element( "div", %opts );
			if( defined $item->{el} )
			{
				$td->appendChild( $item->{el} );
			}
			$tr->appendChild( $td );

# CHANGE FOR JSON METAFIELD
if( $item->{el}->isa( "XML::LibXML::Element" ) ) {
	my $attribute_name = $item->{el}->getAttribute( "name" );
	$self->generate_javascript( $session, $value, $attribute_name, $frag );
}
		}
		$table->appendChild( $tr );
		$y++;
	}

	my $extra_params = URI->new( 'http:' );
	$extra_params->query( $self->{input_lookup_params} );
	my @params = (
		$extra_params->query_form,
		field => $self->name
	);
	if( defined $obj )
	{
		push @params, dataobj => $obj->id;
	}
	if( defined $self->{dataset} )
	{
		push @params, dataset => $self->{dataset}->id;
	}
	$extra_params->query_form( @params );
	$extra_params = "&" . $extra_params->query;

	my $componentid = substr($basename, 0, length($basename)-length($self->{name})-1);
	my $url = EPrints::Utils::js_string( $self->{input_lookup_url} );
	my $params = EPrints::Utils::js_string( $extra_params );
	$frag->appendChild( $session->make_javascript( <<EOJ ) );
new Metafield ('$componentid', '$self->{name}', {
	input_lookup_url: $url,
	input_lookup_params: $params
});
EOJ

	return $frag;
}

# Generates the JavsScript to both display our subfields, 
# and to write any changes to those subfields to the JSON object that EPrints will pick up and save to the database
# Three render formats (see README), but all use the same underlying JS code for the fields, 
# although the table also requires a row parameter as it is storing a JSON array
sub generate_javascript
{
	my( $self, $session, $value, $attribute_name, $frag, $render_only ) = @_;

	my $parent_name = $self->{name};
	my $target_field = "target_field_$attribute_name";
	my $target_area = "$target_field.parentElement";

	# Creates an HTML element (or elements) from a string and returns it, this won't work for elements which must be contained in another element like '<tr>'
	my $js_string = "function createElement(text) { return document.createRange().createContextualFragment(text).firstChild; }";
	$js_string .= "const target_field_$attribute_name = document.querySelector('textarea[name=\"$attribute_name\"]');";
	$js_string .= "$target_field.style.display = 'none';";

	my @readonly_fields;
	if( defined( $self->{readonly_fields} ) )
	{
		@readonly_fields = split( /[\s]+/, $self->{readonly_fields} );
	}
	my @hidden_fields;
	if( defined( $self->{hidden_fields} ) )
	{
		@hidden_fields = split( /[\s]+/, $self->{hidden_fields} );
	}

	my $value_obj;
	if( $value )
	{
		# If someone has put non-JSON into a JSON field, let's clear it
		eval {
			$value_obj = from_json( $value );
		} or do {
			$value = undef;
			$js_string .= "$target_field.value = '';";
		}
	}

	my $config = $self->{json_config};

	if( $self->{render_table} )
	{
		$js_string .= "const div_$attribute_name = $target_area.appendChild(createElement('<div class=\"json_field\" name=\"div_${attribute_name}\">'));";

		my $table_row_count = $self->{table_row_count};
		if( $self->{table_dynamic_row_count} && defined $value_obj )
		{
			$table_row_count = scalar @{$value_obj};
		}

		if( !$self->{table_hide_table} )
		{
			$js_string .= "const table_$attribute_name = div_$attribute_name.appendChild(createElement('<table name=\"table_$attribute_name\">'));";
			$js_string .= "table_$attribute_name.insertAdjacentHTML('beforeend', '<thead><tr></tr></thead>');";
			for my $field_config( @{$config} )
			{
				my $field = $field_config->{name};
				next if any { $_ eq $field } @hidden_fields;

				my $width = $field_config->{table_width};
				if( !defined $width ) {
					$width = (100 / scalar @$config) . '%';
				}
				my $field_name = $session->html_phrase( "eprint_fieldname_${parent_name}_$field" );
				$field_name =~ s/(['\\])/\\$1/g;
				$js_string .= "table_$attribute_name.firstChild.firstChild.insertAdjacentHTML('beforeend', '<th style=\"width:${width}\">$field_name</th>');";
			}

			$js_string .= "table_$attribute_name.insertAdjacentHTML('beforeend', '<tbody>');";
			$js_string .= "const tbody_$attribute_name = table_$attribute_name.lastChild;";

			my $first_attribute_name = $config->[0]->{name};
			my $parent_row_num = 0;

			for( my $row = 0; $row < $table_row_count; $row++ )
			{
				my $title = $value_obj->[$row]->{$first_attribute_name};
				if( !$title || ( $title ne "__json_field_control__skip" && $title ne "<p>__json_field_control__skip</p>" ) )
				{
					$parent_row_num = $row;
				}

				my $style = "";
				if( $value_obj->[$row]->{__hidden} )
				{
					$style = "display:none;";
				}

				$js_string .= "tbody_$attribute_name.insertAdjacentHTML('beforeend', '<tr name=\"table_${attribute_name}_row_${row}\" class=\"table_${attribute_name}_parent_row_${parent_row_num}\" style=\"${style}\">');";
				my $table_row = "tbody_$attribute_name.lastChild";
				for my $field_config( @{$config} )
				{
					my $field_name = $field_config->{name};
					next if any { $_ eq $field_name } @hidden_fields;

					$js_string .= "$table_row.insertAdjacentHTML('beforeend', '<td name=\"table_${attribute_name}_row_${row}_field_${field_name}\">');";
					my $table_cell = "$table_row.lastChild";

					my $value = $value_obj->[$row]->{$field_name};

					if( $render_only )
					{
						$js_string .= $self->generate_javascript_field_render_only( $session, $field_config, $table_cell, $attribute_name . '_row_' . $row, $parent_name, $frag, $value, $target_field, $row, \@readonly_fields, \@hidden_fields, $table_row_count );
					}
					else
					{
						$js_string .= $self->generate_javascript_field( $session, $field_config, $table_cell, $attribute_name . '_row_' . $row, $parent_name, $frag, $value, $target_field, $row, \@readonly_fields, \@hidden_fields, $table_row_count );
					}
				}
			}

			if( !$render_only && $self->{table_dynamic_row_count} )
			{
				my $add_row = $session->html_phrase( "MetaField/Json:add_row" );
				$js_string .= <<"EOJ";
$target_area.insertAdjacentHTML('beforeend', '<div style="float: right; margin-top: -10px;"><a>$add_row</a></div>');
$target_area.lastChild.addEventListener('click', function() {
	var json_str = ${target_field}.value;
	var json = {};
	if( json_str ) {
		json = JSON.parse(json_str.prepare_json_parse());
	} else {
		json = [];
		for( var i = 0; i < ${table_row_count}; i++ ) {
			json[i] = {};
		}
	}
	json[${table_row_count}] = {};
	${target_field}.value = JSON.stringify(json);
	document.querySelector('input[name="_action_save"]').dispatchEvent(new Event('click'));
});
EOJ
			}
		}

		if( $self->{table_allow_hide_rows} && $self->{table_show_hide_rows} )
		{
			if( defined $self->{table_hide_rows_render_js} && $session->can_call( $self->{table_hide_rows_render_js} ) )
			{
				$js_string .= $session->call( $self->{table_hide_rows_render_js}, $session, $attribute_name, $config->[0]->{name}, $table_row_count, $value_obj, $target_field );
			}
			else
			{
				my $disabled = $render_only ? 'disabled' : '';
				$js_string .= "const hide_rows_$attribute_name = div_$attribute_name.insertBefore(createElement('<select name=\"hide_rows_$attribute_name\" multiple=\"multiple\" style=\"margin-bottom: 10px;\" $disabled>'), div_$attribute_name.firstChild);";
				$js_string .= "div_$attribute_name.insertAdjacentHTML('afterbegin', '<p>" . $session->html_phrase( "MetaField/Json:hide_rows" ) . "</p>');";

				my $first_attribute_name = $config->[0]->{name};
				for( my $row = 0; $row < $table_row_count; $row++ )
				{
					my $title = $value_obj->[$row]->{$first_attribute_name};
					if( $title && ( $title eq "__json_field_control__skip" || $title eq "<p>__json_field_control__skip</p>" ) )
					{
						next;
					}
					if( !$title )
					{
						$title = "";
					}
					my $selected = "";

					if( !$value_obj->[$row]->{__hidden} ) {
						$selected = "selected";
					}

					$js_string .= "hide_rows_$attribute_name.insertAdjacentHTML('beforeend', '<option value=\"$row\" ${selected}>${title}</option>');";
				}

				if( !$render_only ) {
					$js_string .= <<"EOJ";
hide_rows_$attribute_name.addEventListener('change', function() {
  var json_str = $target_field.value;
  var json = {};
  if( json_str ) {
    json = JSON.parse(json_str.prepare_json_parse());
  } else {
    return;
  }

  for (const element of hide_rows_$attribute_name.children) {
    const val = element.value;
    if(element.selected) {
      tbody_$attribute_name.children[val].style.display = '';
      delete json[val]['__hidden'];
    } else {
      tbody_$attribute_name.children[val].style.display = 'none';
      json[val]['__hidden'] = 1;
    }
  }

  ${target_field}.value = JSON.stringify(json);
});
hide_rows_$attribute_name.dispatchEvent(new Event('change'));
EOJ
				}
			}
		}
	}
	elsif( $self->{display_as_list} )
	{
		$js_string .= "$target_area.insertAdjacentHTML('beforeend', '<div class=\"json_field_list\">');";
		$js_string .= "const table_$attribute_name = $target_area.lastChild.appendChild(createElement('<table name=\"table_$attribute_name\">'));";

		$js_string .= "table_$attribute_name.insertAdjacentHTML('beforeend', '<tbody>');";

		my @table_rows;
		my $row_index = 0;
		my $cols = $self->{display_as_list_cols};

		my $item_count = scalar @{$config};
		my %unique_hidden_fields = map { $_ => undef } @hidden_fields;
		for my $hidden_field( keys %unique_hidden_fields ) {
			$item_count-- if any {$_->{name} eq $hidden_field} @{$config};
		}
		my $split_point = $item_count / $cols;

		for my $field_config( @{$config} )
		{
			my $field = $field_config->{name};
			next if any {$_ eq $field} @hidden_fields;

			if( !(defined $table_rows[$row_index]) )
			{
				$js_string .= "table_$attribute_name.lastChild.insertAdjacentHTML('beforeend', '<tr name=\"table_${attribute_name}_row_${field}\">');";
				$table_rows[$row_index] = "table_$attribute_name.lastChild.children[$row_index]";
			}

			my $table_row = $table_rows[$row_index];

			my $field_name = $session->html_phrase( "eprint_fieldname_${parent_name}_$field" );
			$field_name =~ s/(['\\])/\\$1/g;
			$js_string .= "$table_row.insertAdjacentHTML('beforeend', '<th>$field_name</th>');";

			$js_string .= "$table_row.insertAdjacentHTML('beforeend', '<td>');";
			my $table_cell = "$table_row.lastChild";
			my $value = $value_obj->{$field};

			if( $render_only )
			{
				$js_string .= $self->generate_javascript_field_render_only( $session, $field_config, $table_cell, $attribute_name . '_row_' . $field, $parent_name, $frag, $value, $target_field, undef, \@readonly_fields, \@hidden_fields, undef );
			}
			else
			{
				$js_string .= $self->generate_javascript_field( $session, $field_config, $table_cell, $attribute_name . '_row_' . $field, $parent_name, $frag, $value, $target_field, undef, \@readonly_fields, \@hidden_fields, undef );
			}

			if( $row_index < $split_point-1 )
			{
				$row_index++;
			}
			else
			{
				$row_index = 0;
			}
		}
	}
	elsif( $render_only && $self->{render_view_as_table} )
	{
		$js_string .= "$target_area.insertAdjacentHTML('beforeend', '<div class=\"json_field_list\"><table name=\"table_${attribute_name}\"></table></div>');";
		$js_string .= "table_$attribute_name.insertAdjacentHTML('beforeend', '<tbody>');";
		for my $field_config( @{$config} )
		{
			my $field_name = $field_config->{name};
			my $value = $value_obj->{$field_name};

			$js_string .= $self->generate_javascript_field_render_only( $session, $field_config, $target_area, $attribute_name, $parent_name, $frag, $value, $target_field, undef, \@readonly_fields, \@hidden_fields, undef );
		}
	}
	else
	{
		for my $field_config( @{$config} )
		{
			my $field_name = $field_config->{name};
			my $value = $value_obj->{$field_name};

			if( $render_only )
			{
				$js_string .= $self->generate_javascript_field_render_only( $session, $field_config, $target_area, $attribute_name, $parent_name, $frag, $value, $target_field, undef, \@readonly_fields, \@hidden_fields, undef );
			}
			else
			{
				$js_string .= $self->generate_javascript_field( $session, $field_config, $target_area, $attribute_name, $parent_name, $frag, $value, $target_field, undef, \@readonly_fields, \@hidden_fields, undef );
			}

		}
	}

	$frag->appendChild( $session->make_javascript( $js_string ) );
}

sub generate_javascript_field
{
	my( $self, $session, $field_config, $target_area, $attribute_name, $parent_name, $frag, $field_value, $target_field, $row, $readonly_fields, $hidden_fields, $table_row_count ) = @_;

	# Hacky little thing to not render rows in a table which are 'multi-lined'
	if( $field_value && ( $field_value eq "__json_field_control__skip" || $field_value eq "<p>__json_field_control__skip</p>" ) )
	{
		return "";
	}

	my $field = $field_config->{name};
	my $field_div = "div_${attribute_name}_$field";

	if( any {$_ eq $field} @{$hidden_fields} )
	{
		return "";
	}

	my $js_string = "";
	my $div_class = "ep_sr_component json_$parent_name";
	$js_string .= "const div_${attribute_name}_$field = $target_area.appendChild(createElement('<div class=\"$div_class\" name=\"div_${attribute_name}_$field\">'));";

	if( !$self->{render_table} && !$self->{display_as_list} )
	{
		my $field_name = $session->html_phrase( "eprint_fieldname_${parent_name}_${field}" );
		if( $field_config->{required} ) 
		{
			$field_name = $session->html_phrase( "sys:ep_form_required", label => $field_name );
		}
		$field_name =~ s/\r\n|\r|\n//g;
		$field_name =~ s/(['\\])/\\$1/g;
		$js_string .= "${field_div}.insertAdjacentHTML('beforeend', '<div class=\"ep_sr_title\">" . $field_name . "</div>');";

		my $field_help = $session->html_phrase( "eprint_fieldhelp_${parent_name}_${field}" );
		$field_help =~ s/\r\n|\r|\n//g;
		$field_help =~ s/(['\\])/\\$1/g;
		$js_string .= "${field_div}.insertAdjacentHTML('beforeend', '<div class=\"ep_sr_help\">" . $field_help . "</div>');";
	}

	my $js_input_name = "input_${attribute_name}_${field}";
	my $js_parsing_addition = "";

	my $type = $field_config->{type};

	my $readonly = "";
	if( ( $self->{readonly} && ( $self->{readonly} eq 1 || $self->{readonly} eq "yes" ) ) || any {$_ eq $field} @{$readonly_fields} )
	{
		$readonly = "readonly";
	}

	my $js_input_string;
	if( $type eq "text" )
	{
		$js_input_string = "<input type='text' id='${js_input_name}' class='ep_eprint_${parent_name}_${field}' size='50' ${readonly}>";
	}
	elsif( $type eq "number" )
	{
		$js_input_string = "<input type='number' id='${js_input_name}' class='ep_eprint_${parent_name}_${field}' ${readonly}>";
	}
	elsif( $type eq "longtext" )
	{
		$js_input_string = "<textarea id='${js_input_name}' class='ep_eprint_${parent_name}_${field}' ${readonly}>";
		$js_parsing_addition = "value_str = value_str.replaceAll('\\n', '\\\\n');";
	}
	elsif( $type eq "boolean" )
	{
		if( $readonly ne "" )
		{
			$readonly = "disabled";
		}
		$js_input_string = "<input type='checkbox' class='ep_eprint_${parent_name}_${field}' ${readonly}>";
		$js_parsing_addition = "value_str = this.checked";
	}
	elsif( $type eq "richtext" )
	{
		$frag->appendChild( $session->make_element( "script", src=> "/javascript/tinymce.min.js" ) );
		if( $readonly eq "" )
		{
			$frag->appendChild( $session->make_javascript( "document.addEventListener('DOMContentLoaded', function(\$){ " . $self->{richtext_init_func} . "(\"#${js_input_name}\"); })" ) );
		}
		else
		{
			$frag->appendChild( $session->make_javascript( "document.addEventListener('DOMContentLoaded', function(\$){ " . $self->{richtext_init_func_readonly} . "(\"#${js_input_name}\"); })" ) );
		}
		$js_input_string = "<textarea id='${js_input_name}' class='ep_eprint_${parent_name}_${field}' ${readonly}>";
	}
	elsif( $type eq "namedset" && $field_config->{set_name} )
	{
		if( $readonly ne "" )
		{
			$readonly = "disabled";
		}

		my $multiple = "";
		if( $field_config->{multiple} )
		{
			$multiple = "multiple='multiple'";
		}
		$js_input_string = "<select id='${js_input_name}' class='ep_eprint_${parent_name}_${field}' ${multiple} ${readonly}>";
		my @tags = $self->{repository}->get_types( $field_config->{set_name} );
		if( !$field_config->{multiple} )
		{
			$js_input_string .= "<option value=''></option>";
		}

		foreach( @tags )
		{
			my $option_phrase = $session->render_type_name( $field_config->{set_name}, $_ );
			# Escape any ' in the phrase, cos it will break JS
			$option_phrase =~ s/\'/\\\'/g;

			$js_input_string .= "<option value='${_}'>$option_phrase</option>";
		}
	}
	else
	{
		return "";
	}

	$js_string .= "const $js_input_name = createElement(\"$js_input_string\");";
	$js_string .= "$field_div.appendChild($js_input_name);";

	if( $field_value )
	{
		$field_value =~ s/(\r\n|\r|\n)//g;
		$field_value =~ s/\\/\\\\/g;

		if( $type eq "boolean" )
		{
			$js_string .= "${js_input_name}.checked = `${field_value}`;";
		}
		elsif( $type eq "namedset" && $field_config->{set_name} && $field_config->{multiple} )
		{
			my $field_value_encoded = encode_json( ${field_value} );
			$js_string .= "${js_input_name}.value = ${field_value_encoded};";
		}
		else
		{
			$js_string .= "${js_input_name}.value = `${field_value}`;";
		}
	}

	my $js_json_parsing;

	if( $self->{render_table} )
	{
		$js_json_parsing = <<"EOJ";
var json_str = ${target_field}.value;
var json = {};
if( json_str ) {
	json = JSON.parse(json_str.prepare_json_parse());
} else {
	json = [];
	for( var i = 0; i < ${table_row_count}; i++ ) {
		json[i] = {};
	}
}
var value_str = $js_input_name.value;
${js_parsing_addition}
json[${row}]['$field'] = value_str;
${target_field}.value = JSON.stringify(json);
EOJ
	}
	else
	{
		$js_json_parsing = <<"EOJ";
var json_str = ${target_field}.value;
var json = {};
if( json_str ) {
	json = JSON.parse(json_str.prepare_json_parse());
}
var value_str = $js_input_name.value;
${js_parsing_addition}
json['$field'] = value_str;
${target_field}.value = JSON.stringify(json);
EOJ
	}

	$js_string .= "${js_input_name}.addEventListener('change', function() { " . $js_json_parsing . "});";


if( $self->{input_lookup_url} )
{
	my $componentid = substr($attribute_name, 0, length($attribute_name)-length($self->{name})-1);
	my $url = EPrints::Utils::js_string( $self->{input_lookup_url} );
	my $extra_params_1 = URI->new( 'http:' );

	$extra_params_1->query( $self->{input_lookup_params} );
	my @params = (
		field => $self->name,
		json_field => $field
	);
	my $extra_params_2 = URI->new( 'http:' );
	$extra_params_2->query_form( @params );
	$extra_params_1 = "&" . $extra_params_2->query . "&" . $extra_params_1->query;
	my $params = EPrints::Utils::js_string( $extra_params_1 );
	$js_string .= <<"EOJ";
$js_input_name.parentElement.insertAdjacentHTML('beforeend', "<div id='${js_input_name}_drop' class='ep_drop_target', style='position: absolute; display: none;'>");
$js_input_name.parentElement.insertAdjacentHTML('beforeend', "<div id='${js_input_name}_drop_loading' class='ep_drop_loading' style='position: absolute; display: none;'>");
ep_autocompleter(
	$js_input_name,
	'${js_input_name}_drop',
	$url,
	{
		relative: '$js_input_name',
		component: $componentid
	},
	['$js_input_name'],
	[],
	$params
);
EOJ
}

	return $js_string;
}

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;

	$defaults{json_config} = EP_PROPERTY_REQUIRED;
	$defaults{richtext_init_func} = "initTinyMCE";
	$defaults{richtext_init_func_readonly} = "initTinyMCEReadOnly";

	$defaults{readonly_fields} = EP_PROPERTY_UNDEF;
	$defaults{hidden_fields} = EP_PROPERTY_UNDEF;

	$defaults{render_table} = 0;
	$defaults{table_row_count} = 1;
	$defaults{table_dynamic_row_count} = 0;
	$defaults{table_allow_hide_rows} = 0;
	$defaults{table_show_hide_rows} = 1;
	$defaults{table_hide_table} = 0;
	$defaults{table_hide_rows_render_js} = EP_PROPERTY_UNDEF;

	$defaults{display_as_list} = 0;
	$defaults{display_as_list_cols} = 2;

	$defaults{render_view_as_table} = 0;

	return %defaults;
}

sub form_value
{
	my( $self, $session, $object, $prefix ) = @_;

	my $value = $self->SUPER::form_value( $session, $object, $prefix );

	# validate the JSON
	if( $value )
	{
		eval {
			from_json( $value );
		} or do {
			$value = undef;
		};
	}

	return $value;
}

sub html_text_escape
{
	my( $str ) = @_;

	$str =~ s/&/&amp;/g;
	$str =~ s/>/&gt;/g;
	$str =~ s/</&lt;/g;
	$str =~ s/'/&apos;/g;

	return $str;
}

sub render_value_actual
{
	my( $self, $session, $value, $alllangs, $nolink, $object ) = @_;

	my $html = $session->make_doc_fragment();

	#something unique so when on the same page multiple times doesn't go crazy
	my $attribute_name = $self->{name} . '_' . APR::UUID->new->format();
	# but no dashes
	$attribute_name =~ s/-//g;
	my $div = $session->make_element( "div" );
	$div->appendChild( $session->make_element( "textarea", name => $attribute_name ) );
	$html->appendChild( $div );

	$self->generate_javascript( $session, $value, $attribute_name, $html, 1 );

	return $html;

}

sub generate_javascript_field_render_only
{
	my( $self, $session, $field_config, $target_area, $attribute_name, $parent_name, $frag, $field_value, $target_field, $row, $readonly_fields, $hidden_fields ) = @_;

	# Hacky little thing to not render rows in a table which are 'multi-lined'
	if( $field_value && ( $field_value eq "__json_field_control__skip" || $field_value eq "<p>__json_field_control__skip</p>" ) )
	{
		return "";
	}

	if( $field_value )
	{
		$field_value =~ s/(\r\n|\r|\n)//g;
	}
	else
	{
		$field_value = "";
	}


	my $field = $field_config->{name};
	my $field_div = "div_${attribute_name}_$field";

	my $js_string = "";
	my $div_class = "ep_sr_component json_$parent_name";
	if( $self->{render_view_as_table} )
	{
		$js_string .= "const tr_${attribute_name}_$field = $target_area.appendChild(createElement('<tr name=\"div_${attribute_name}_$field\">'));";
		$field_div = "tr_${attribute_name}_$field";
	}
	else
	{
		$js_string .= "const div_${attribute_name}_$field = $target_area.appendChild(createElement('<div class=\"$div_class\" name=\"div_${attribute_name}_$field\">'));";
	}

	if( !$self->{render_table} && !$self->{display_as_list} && !$self->{render_view_as_table} )
	{
		my $field_name = $session->html_phrase( "eprint_fieldname_${parent_name}_${field}" );
		$field_name =~ s/\r\n|\r|\n//g;
		$field_name =~ s/(['\\])/\\$1/g;
		$js_string .= "${field_div}.insertAdjacentHTML('beforeend', '<div class=\"ep_sr_title\">$field_name</div>');";

		my $field_help = $session->html_phrase( "eprint_fieldhelp_${parent_name}_${field}" );
		$field_help =~ s/\r\n|\r|\n//g;
		$field_help =~ s/(['\\])/\\$1/g;
		$js_string .= "${field_div}.insertAdjacentHTML('beforeend', '<div class=\"ep_sr_help\">$field_help</div>');";
	}
	elsif( $self->{render_view_as_table} )
	{
		my $field_name = $session->html_phrase( "eprint_fieldname_${parent_name}_${field}" );
		$field_name =~ s/\r\n|\r|\n//g;
		$field_name =~ s/(['\\])/\\$1/g;
		$js_string .= "${field_div}.insertAdjacentHTML('beforeend', '<th>$field_name</th><td></td>');";
	}

	my $js_input_name = "input_${attribute_name}_${field}";
	my $type = $field_config->{type};

	my $js_input_string;
	if( $type eq "text" || $type eq "number" || $type eq "longtext" )
	{
		$js_input_string = "<p id='$js_input_name'>$field_value</p>";
	}
	elsif( $type eq "richtext" )
	{
		$js_input_string = "<div id='$js_input_name'>$field_value</div>";
	}
	elsif( $type eq "namedset" && $field_config->{set_name} )
	{
		$js_input_string = "<p id='$js_input_name'>";
		if( $field_config->{multiple} )
		{
			foreach( @{$field_value} )
			{
				my $set_value = "";
				$set_value = $session->render_type_name( $field_config->{set_name}, $_ ) if $_;
				$js_input_string .= "$set_value";
			}
		}
		else
		{
			my $set_value = "";
			$set_value = $session->render_type_name( $field_config->{set_name}, $field_value ) if $field_value;
			$js_input_string .= "$set_value";
		}
		$js_input_string .= "</p>";
	}
	elsif( $type eq "boolean" )
	{
		my $readonly = "disabled";
		my $checked = $field_value eq '' ? '' : "checked";
		$js_input_string = "<input type='checkbox' class='ep_eprint_${parent_name}_$field' $readonly $checked>";
	}
	else
	{
		return "";
	}

	$js_string .= "$js_input_name = createElement(`$js_input_string`);";

	if( $self->{render_view_as_table} )
	{
		$js_string .= "$field_div.lastChild.appendChild($js_input_name);";
	}
	else
	{
		$js_string .= "$field_div.appendChild($js_input_name);";
	}

	return $js_string;
}

sub validate
{
	my( $self, $session, $value, $object ) = @_;

	my @problems = $session->get_repository->call(
		"validate_field",
		$self,
		$value,
		$session );

	$self->{repository}->run_trigger( EPrints::Const::EP_TRIGGER_VALIDATE_FIELD(),
		field => $self,
		dataobj => $object,
		value => $value,
		problems => \@problems,
	);

	# check required fields (only for non-table mode for now)
	if( !$self->{render_table} )
	{
		my $value_obj;
		if( $value )
		{
			# If someone has put non-JSON into a JSON field, let's clear it
			eval {
				$value_obj = from_json( $value );
			};
		}

		my $config = $self->{json_config};
		for my $sub_field( @{$config} )
		{
			next if !$sub_field->{required};

			my $sub_value = $value_obj->{$sub_field->{name}};
			next if EPrints::Utils::is_set( $sub_value );

			my $fieldname = $session->make_element( "span", class => "ep_problem_field:" . $self->{name} );
			$fieldname->appendChild( $self->render_name( $session, $self->{dataobj} ) );
			my $problem = $session->html_phrase(
				"lib/eprint:not_done_part",
				partname => $session->html_phrase( "eprint_fieldname_" . $self->{name} . "_" . $sub_field->{name} ),
				fieldname => $fieldname,
			);
			push @problems, $problem;
		}
	}

	return @problems;
}

sub parse
{
	my( $json_str, $default_value ) = @_;

	my $object = $default_value;

	if( defined $json_str )
	{
		try {
			$object = from_json $json_str;
		} catch {
			print STDERR "Exception parsing $json_str: @_\n";
		};
	}

	return $object;
}

sub parse_and_get_field
{
	my( $json_str, $field_name, $default_value ) = @_;

	my $object = EPrints::MetaField::Json::parse( $json_str );
	my $value = $default_value;

	try {
		if( defined $object && $object->{$field_name} )
		{
			$value = $object->{$field_name};
		}
	} catch {
		print STDERR "Exception getting $field_name from $json_str: @_\n";		
	};

	return $value;
}

sub encode
{
	my( $obj, $default_value ) = @_;

	my $value = $default_value;

	try {
		$value = to_json( $obj );
	} catch {
		print STDERR "Exception - failed encode: @_\n";
	};

	return $value;
}

1;

