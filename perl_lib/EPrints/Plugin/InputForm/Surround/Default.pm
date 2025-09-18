=head1 NAME

EPrints::Plugin::InputForm::Surround::Default

=cut

package EPrints::Plugin::InputForm::Surround::Default;

use strict;

use EPrints::Template qw( :template_phrase );

our @ISA = qw/ EPrints::Plugin /;


sub render_title
{
	my( $self, $component ) = @_;

	my $title = $component->render_title( $self );

	if( $component->is_required )
	{
                my $required = $self->{session}->make_element("img",
                        src => $self->{session}->html_phrase( "sys:ep_form_required_src" ),
                        class => "ep_required",
                        alt => $self->{session}->html_phrase( "sys:ep_form_required_alt" ));
                $required->appendChild( $self->{session}->make_text( " " ) );
                $required->appendChild( $title );
                $title = $required;
	}

	return $title;
}


sub render
{
	my( $self, $component ) = @_;

	my $item = {
		prefix => $component->{prefix},
		handled_fields => [],
	};

	my $comp_name = $component->get_name();

	my $label_id = $component->{prefix} . "_label";
	$label_id = $component->{prefix} . "_".$component->{config}->{field}->{name}."_label" if defined $component->{config}->{field} && $component->{config}->{field}->{name};
	if ( defined $component->{config} && defined $component->{config}->{field} && ( ( defined $component->{config}->{field}->{form_input_style} &&  $component->{config}->{field}->{form_input_style} eq "checkbox" ) || ( $component->{config}->{field}->{input_style} && $component->{config}->{field}->{input_style} eq "checkbox" ) ) )
	{
		$label_id = $component->{prefix} . "_".$component->{config}->{field}->{name}."_legend_label";
	} 

	foreach my $field_id ( $component->get_fields_handled )
	{
		push @{$item->{handled_fields}}, { handled_field => $self->{session}->make_element( "a", name=>$field_id ) };
	}

	my $barid = $component->{prefix}."_titlebar";
	my $title_bar_class="";
	my $content_class="";
	if( $component->is_collapsed )
	{
		$title_bar_class = "ep_no_js";
		$content_class = "ep_no_js";
	}
		
	$item->{title_bar} = { class => $title_bar_class, id => $barid };
	$item->{title_div} = { id => $label_id };
	$item->{content} = { class => $content_class };
	$item->{content_inner} = { id => $component->{prefix}."_content_inner" };

	$item->{no_toggle} = $component->{no_toggle};

	# Help rendering
	$item->{has_help} = $component->has_help && !$component->{no_help} ? 1 : 0;
	if( $component->has_help && !$component->{no_help} )
	{
		$item->{help_item} = $self->_render_help( $component );
	}

	my $imagesurl = $self->{session}->get_repository->get_conf( "rel_path" );

	$item->{ajax_content_target} = { id => $component->{prefix}."_ajax_content_target" };
	$item->{contents} = $component->render_content( $self );
	$item->{is_collapsed} = $component->is_collapsed;
	if( $component->is_collapsed )
	{
		my $colbarid = $component->{prefix}."_col";
		$item->{col_div} = { id => $colbarid };

		my $contentid = $component->{prefix}."_content";
		my $main_id = $component->{prefix};
		$item->{col_link} = { render_title => $component->render_title( $self ), contentid => $contentid, main_id => $main_id, colbarid => $colbarid, barid => $barid };
	}
	else
	{
		$item->{render_title} = $self->render_title( $component );
	}
	
        return $self->{session}->template_phrase( "view:perl_lib/EPrints/Plugin/InputForm/Surround/Default:render", { item => $item } );
}

# this adds an expand/hide icon to the title bar that enables showing/hiding
# help and adds the help text to the content_inner
sub _render_help
{
	my( $self, $component ) = @_;
	
	my $help_item = {
		prefix => $component->{prefix}."_help",
		render_help => $component->render_help( $self )
	};

	# add the help text to the main part of the component
	my $hide_class = !$component->{no_toggle} ? "ep_no_js" : "";
	$help_item->{hide_class} = $hide_class;

	# don't render a toggle button
	$help_item->{no_toggle} = $component->{no_toggle};

	return $help_item;
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

