######################################################################
#
# EPrints::Box
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Box> - Class to render cute little collapsible/expandable 
Web 2.0ish boxes.

=head1 DESCRIPTION

This just provides a function to render boxes in the EPrints style.

=head2 SYNOPSIS

	use EPrints;

	# an XHTML DOM box with a title and some content that starts rolled up.
	EPrints::Box(
		   handle => $handle,
		       id => "my_box",
		    title => $my_title_dom,
		  content => $my_content_dom,
		collapsed => 1,
	); 

=head1 METHODS

=cut

package EPrints::Box;

use strict;

######################################################################
=pod

=over 4

=item $box_xhtmldom = EPrints::Box::render( %options )

Render a collapsible/expandable box to which content can be added. The 
box is in keeping with the eprints style.

Required Options:

B<C<$options{handle}>> - Current C<$handle>.

B<C<$options{id}>> - ID attribute of the box. E.g. <div id="my_box">

B<C<$options{title}>> - XHTML DOM of the title of the box. N.B. The exact 
object will be used not a clone of the object.

B<C<$options{content}>> - XHTML DOM of the content of the box. N.B. The 
exact object will be used not a clone of the object.

Optional Options:

B<C<$options{collapsed}>> -Should the box start rolled up. Defaults to 
C<false>.

B<C<$options{content_style}>> - The CSS style to apply to the content box. 
E.g. C<overflow-y: auto; height: 300px;>

B<C<$options{show_icon_url}>> - The URL of the icon to use instead of the 
B<[+]>

B<C<$options{hide_icon_url}>> - The URL of the icon to use instead of the 
B<[-]>

=cut
######################################################################

sub EPrints::Box::render
{
	my( %options ) = @_;

	if( !defined $options{id} ) { EPrints::abort( "EPrints::Box::render called without a id. Bad bad bad." ); }
	if( !defined $options{title} ) { EPrints::abort( "EPrints::Box::render called without a title. Bad bad bad." ); }
	if( !defined $options{content} ) { EPrints::abort( "EPrints::Box::render called without a content. Bad bad bad." ); }
	if( !defined $options{session} ) { EPrints::abort( "EPrints::Box::render called without a session. Bad bad bad." ); }

	my $class = "";
	$class = $options{class} if defined $options{class};

	my $session = $options{session};
	my $imagesurl = $session->config( "rel_path" );
	if( !defined $options{show_icon_url} ) { $options{show_icon_url} = "$imagesurl/style/images/plus.svg"; }
	if( !defined $options{hide_icon_url} ) { $options{hide_icon_url} = "$imagesurl/style/images/minus.svg"; }

	my $id = $options{id};
		
	my $contentid = $id."_content";
	my $colbarid = $id."_colbar";
	my $barid = $id."_bar";

	my $div = $session->make_element( "div", class=>"ep_summary_box $class", id=>$id );

	# Title
	my $div_title = $session->make_element( "div", class=>"ep_summary_box_title" );
	$div->appendChild( $div_title );

	my $nojstitle = $session->make_element( "div", class=>"ep_no_js" );
	$nojstitle->appendChild( $session->clone_for_me( $options{title},1 ) );
	$div_title->appendChild( $nojstitle );

	my $bar = $div_title->appendChild( $session->make_element( 'div', class => 'ep_only_js' ) );
	my $checkbox_label = $bar->appendChild( $session->make_element( 'label', class => 'ep_styled_checkbox' ) );
	my $checkbox = $checkbox_label->appendChild( $session->make_element(
		'input',
		type => 'checkbox',
		id => "${contentid}_checkbox",
		onclick => "EPJS_checkboxSlide('${contentid}')"
	) );
	$checkbox_label->appendChild( $session->make_element( 'img', class => 'ep_unchecked', src => $options{show_icon_url}, alt => '+' ) );
	$checkbox_label->appendChild( $session->make_element( 'img', class => 'ep_checked', src => $options{hide_icon_url}, alt => '-' ) );
	my $checkbox_span = $checkbox_label->appendChild( $session->make_element( 'span', class => 'align-middle' ) );
	$checkbox_span->appendChild( $session->clone_for_me( $options{title}, 1 ) );
	
	# Body	
	my $div_body = $session->make_element( "div", class=>"ep_toggleable", id=>$contentid );
	my $div_body_inner = $session->make_element( "div", class => 'ep_summary_box_body', id=>$contentid."_inner", style=>$options{content_style} );
	$div_body->appendChild( $div_body_inner );
	$div->appendChild( $div_body );
	$div_body_inner->appendChild( $options{content} );

	if( $options{collapsed} ) {
		$div_body->setAttribute( "style", "display: none" ); 
	} else {
		$checkbox->setAttribute( 'checked', 'checked' );
	}

	return $div;
}

1;

=back

=head1 COPYRIGHT

=begin COPYRIGHT

Copyright 2022 University of Southampton.
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

