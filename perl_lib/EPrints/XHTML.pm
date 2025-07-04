######################################################################
#
# EPrints::XHTML
#
######################################################################
#
#
######################################################################


=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::XHTML> - XHTML Module

=head1 SYNOPSIS

	$xhtml = $repo->xhtml;

	$utf8_string = $xhtml->to_xhtml( $dom_node, %opts );

	$xhtml_dom_node = $xhtml->input_field( $name, $value, type => "text" );
	$xhtml_dom_node = $xhtml->hidden_field( $name, $value );
	$xhtml_dom_node = $xhtml->text_area_field( $name, $value, rows => 4 );
	$xhtml_dom_node = $xhtml->form( "get", $url );

	$xhtml_dom_node = $xhtml->data_element( $name, $value, indent => 4 );

	$page = $xhtml->page( %opts );

=head2 tree()

	$xhtml->tree([ # dl
		[ "fruit", # dt
			[ "apple", "orange", ], # ul {li, li}
		],
		[ "vegetable", # dt
			[ "potato", "carrot", ], # ul {li, li}
		],
		[ "animal", # dt
			[ "cat", # dt
				[ "lion", "leopard", ], # ul {li, li}
			],
		],
		"soup", # ul {li}
		$xml->create_element( "p" ), # <p> is appended
	]);
	
	<dl>
		<dt>fruit</dt>
		<dd>
			<ul>
				<li>apple</li>
				<li>orange</li>
			</ul>
		</dd>
		<dt>vegetable</dt>
		<dd>
			<ul>
				<li>potato</li>
				<li>carrot</li>
			</ul>
		</dd>
		<dt>animal</dt>
		<dd>
			<dl>
				<dt>cat</dt>
				<dd>
					<ul>
						<li>lion</li>
						<li>leopard</li>
					</ul>
				</dd>
			</dl>
		</dd>
	</dl>
	<ul>
		<li>soup</li>
	</ul>
	<p />

=head1 DESCRIPTION

The XHTML object facilitates the creation of XHTML objects.

=head1 METHODS

=over 4

=cut

package EPrints::XHTML;

use EPrints::Const qw( :xml ); # XML node type constants
use strict;

@EPrints::XHTML::COMPRESS_TAGS = qw/br hr img link input meta/;
%EPrints::XHTML::COMPRESS_TAG = map { $_ => 1 } @EPrints::XHTML::COMPRESS_TAGS;

# $xhtml = new EPrints::XHTML( $repository )
#
# Constructor, should be called by Repository only.

sub new($$)
{
	my( $class, $repository ) = @_;

	my $self = bless { repository => $repository }, $class;

	Scalar::Util::weaken( $self->{repository} )
		if defined &Scalar::Util::weaken;

	return $self;
}

=item $node = $xhtml->form( $method [, $action] )

Returns an XHTML form. If $action isn't defined uses the current URL.

=cut

sub form
{
	my( $self, $method, $action ) = @_;
	
	$method = lc($method);
	if( !defined $action )
	{
		$action = $self->{repository}->current_url( query => 0 );
	}

	my $form = $self->{repository}->xml->create_element( "form",
		method => $method,
		'accept-charset' => "utf-8",
		action => $action,
		);
	if( $method eq "post" )
	{
		$form->setAttribute( enctype => "multipart/form-data" );
	}

	# Add a CSRF token to the form if a salt has been set and there is a logged in user.
	if ( defined $self->{repository}->config( "csrf_token_salt" ) && defined $self->{repository}->current_user && $method ne "get" )
        {
		my $csrf_token = $self->{repository}->get_csrf_token();
                my $csrf_token_input = $self->{repository}->xml->create_element( "input",
			id => "csrf_token",
			name => "csrf_token",
			type => "hidden", 
			value => $csrf_token,
                );
		$form->appendChild( $csrf_token_input );
        }

	return $form;
}

=item $node = $xhtml->input_field( $name, $value, %opts )

	$node = $xhtml->input_field( "name", "Bob", type => "text" );

Returns an XHTML input field with name $name and value $value. Specify "noenter" to prevent the form being submitted when the user presses the enter key.

=cut

sub input_field
{
	my( $self, $name, $value, @opts ) = @_;

	my $noenter;
#	my $noid = 0;
	for(my $i = 0; $i < @opts; $i+=2)
	{
		if( $opts[$i] eq 'noenter' )
		{
			(undef, $noenter) = splice(@opts,$i,2);
		}
#		if ( $opts[$i] eq 'type' && $opts[$i+1] eq 'checkbox' )
#		{
#			$noid = 1;
#		}
	}
	if( $noenter )
	{
		push @opts, onKeyPress => 'return EPJS_block_enter( event )';
	}
#	if ( !$noid )
#	{
#		push @opts, id => $name;
#	}

	my %opts = @opts;
	my @opts_item = ();
	for my $key ( keys %opts )
	{
		next if not defined $opts{$key};
		push @opts_item, { key => $key, value => $opts{$key} };
	}

        return $self->{repository}->template_phrase( "view:EPrints/XHTML:input_field", { item => {
                name => $name,
                value => $value,
		opts => \@opts_item,
        } } );
}

=item $node = $xhtml->hidden_field( $name, $value, %opts );

Returns an XHTML hidden input field.

=cut

sub hidden_field
{
	my( $self, $name, $value, @opts ) = @_;

	my %hopts = @opts;
	push @opts, ( 'id', $name ) unless defined $hopts{id};

	return $self->{repository}->xml->create_element( "input",
		name => $name,
		value => $value,
		type => "hidden",
		@opts );
}

=item $node = $xhtml->action_button( $name, $value, %opts )

Creates a submit button that is styled to an EPrints form button.

$value is the text shown on the button.

=cut

sub action_button
{
	my( $self, $name, $value, %opts ) = @_;

	$opts{class} = join ' ', 'ep_form_action_button', ($opts{class}||());
	$opts{role} = "button" unless defined $opts{role};

	return $self->{repository}->xml->create_element( "input",
		name => "_action_$name",
		value => $value,
		type => "submit",
		%opts,
	);
}

=item $node = $xhtml->action_icon( $name, $src, %opts )

Creates an image button that links to $src.

For usability it is strongly recommended to supply the alt= attribute.

=cut

sub action_icon
{
	my( $self, $name, $src, %opts ) = @_;

	return $self->{repository}->xml->create_element( "input",
		name => "_action_$name",
		src => $src,
		type => "image",
		%opts,
	);
}

=item $node = $xhtml->text_area_field( $name, $value, %opts )

Returns an XHTML textarea input.

=cut

sub text_area_field
{
	my( $self, $name, $value, @opts ) = @_;

	my $node = $self->{repository}->xml->create_element( "textarea",
		name => $name,
		id => $name,
		@opts );
	$node->appendChild( $self->{repository}->xml->create_text_node( $value ) );

	return $node;
}

=item $node = $xhtml->data_element( $name, $value, %opts )

Create a new element named $name containing a text node containing $value.

Options:
	indent - amount of whitespace to indent by

=cut

sub data_element
{
	my( $self, $name, $value, @opts ) = @_;

	my $indent;
	for(my $i = 0; $i < @opts; $i+=2)
	{
		if( $opts[$i] eq 'indent' )
		{
			(undef, $indent ) = splice(@opts,$i,2);
			last;
		}
	}

	my $node = $self->{repository}->xml->create_element( $name, @opts );
	$node->appendChild( $self->{repository}->xml->create_text_node( $value ) );

	if( defined $indent )
	{
		my $f = $self->{repository}->xml->create_document_fragment;
		$f->appendChild( $self->{repository}->xml->create_text_node(
			"\n"." "x$indent
			) );
		$f->appendChild( $node );
		return $f;
	}

	return $node;
}

=item $utf8_string = $xhtml->to_xhtml( $node, %opts )

Returns $node as valid XHTML.

=cut

sub to_xhtml
{
	my( $self, $node, %opts ) = @_;

	&_to_xhtml( $node );
}

my %HTML_ENTITIES = (
	'&' => '&amp;',
	'>' => '&gt;',
	'<' => '&lt;',
	'"' => '&quot;',
);

# may take options in the future
sub _to_xhtml
{
	my( $node ) = @_;

	# a single call to "nodeType" is quicker than lots of calls to is()?
	my $type = $node->nodeType;

	my @n = ();
	if( $type == XML_ELEMENT_NODE )
	{
		my $tagname = $node->localName; # ignore prefixes

		$tagname = lc($tagname);

		push @n, '<', $tagname;
		my $seen = {};

		if( $tagname eq "html" )
		{
			push @n, ' xmlns="http://www.w3.org/1999/xhtml"';
		}

		foreach my $attr ( $node->attributes )
		{
			my $name = $attr->nodeName;
			# strip all namespace definitions and prefixes
			next if $name =~ /^xmlns/;
			$name =~ s/^.+://;

			next if( exists $seen->{$name} );
			$seen->{$name} = 1;

			my $value = $attr->nodeValue;
			$value =~ s/([&<>"])/$HTML_ENTITIES{$1}/g;
			utf8::decode($value) unless utf8::is_utf8($value);
			push @n, ' ', $name, '="', $value, '"';
		}

		if( $node->hasChildNodes )
		{
			push @n, '>';
			foreach my $kid ( $node->childNodes )
			{
				push @n, &_to_xhtml( $kid );
			}
			push @n, '</', $tagname, '>';
		}
		elsif( $EPrints::XHTML::COMPRESS_TAG{$tagname} )
		{
			push @n, ' />';
		}
		elsif( $tagname eq "script" )
		{
			push @n, '>// <!-- No script --></', $tagname, '>';
		}
		else
		{
			push @n, '></', $tagname, '>';
		}
	}
	elsif( $type == XML_DOCUMENT_FRAGMENT_NODE )
	{
		foreach my $kid ( $node->getChildNodes )
		{
			push @n, &_to_xhtml( $kid );
		}
	}
	elsif( $type == XML_DOCUMENT_NODE )
	{
		push @n, &_to_xhtml( $node->documentElement );
	}
	else
	{
		push @n, $node->toString; 
		utf8::decode($n[$#n]) unless utf8::is_utf8($n[$#n]);
	}

	return wantarray ? @n : join('', @n);
}

=item $string = $xhtml->to_text_dump( $tree, %opts )

Dumps the XHTML contents of $tree as a utf8 string, stripping tags and converting common HTML layout elements into their plain-text equivalent.

Options:

	width - word-wrap after the given number of columns
	show_links - see below
	preformatted - equivalent to wrapping $tree in <pre></pre>

XHTML elements are removed with the following exceptions:

<br /> is replaced by a newline.

<p>...</p> will have a blank line above and below.

<img /> is replaced with the content of the I<alt> attribute.

<hr /> will insert a line of dashes if B<width> is set.

<a href="foo">bar</a> will be replaced by "bar <foo>" if B<show_links> is set.

=cut

######################################################################

sub to_text_dump
{
	my( $self, $node, %opts ) = @_;

	my $width = exists $opts{width} ? $opts{width} : undef;
	my $show_links = exists $opts{show_links} ? $opts{show_links} : 0;
	my $pre = exists $opts{preformatted} ? $opts{preformatted} : 0;

	my $str = "";
	$self->_to_text_dump( \$str, $node, $width, $pre, $show_links );
	utf8::decode($str) unless utf8::is_utf8($str);

	return $str;
}

sub _to_text_dump
{
	my( $self, $str, $node, $width, $pre, $show_links ) = @_;

	if( $self->{repository}->{xml}->is( $node, 'Text', 'CDataSection' ) )
	{
		my $v = $node->nodeValue();
		$v =~ s/[\s\r\n\t]+/ /g unless( $pre );
		$$str .= $v;
		return;
	}
	elsif( $self->{repository}->{xml}->is( $node, 'NodeList' ) )
	{
# Hmm, a node list, not a node.
		for( my $i=0 ; $i<$node->length ; ++$i )
		{
			$self->_to_text_dump(
					$str,
					$node->item( $i ), 
					$width,
					$pre,
					$show_links );
		}
		return;
	}

	my $name = $node->localName();
	# documentFragment has no localName
	$name = defined $name ? lc($name) : "";

	# empty tags
	if( $name eq 'hr' )
	{
		# <hr /> only makes sense if we are generating a known width.
		$$str .= "\n"."-"x$width."\n" if $width;
		return;
	}
	elsif( $name eq 'br' )
	{
		$$str .= "\n";
		return;
	}

	my $contents = "";
	for( $node->childNodes )
	{
		$self->_to_text_dump( 
				\$contents,
				$_,
				$width, 
				( $pre || $name eq "pre" || $name eq "mail" ),
				$show_links );
	}

	# Handle wrapping block elements if a width was set.
	if( $width && ( $name eq "p" || $name eq "mail" ) )
	{
		$contents = EPrints::Utils::wrap_text( $contents, $width );
	}

	if( $name eq "fallback" )
	{
		$contents = "*".$contents."*";
	}
	elsif( $name eq "p" )
	{
		$contents =~ s/^(?:\n\n)?/\n\n/ if $$str !~ /\n\n$/;
		$contents =~ s/(?:\n)?$/\n/;
	}
	elsif( $name eq "img" )
	{
		$contents = $node->getAttribute( "alt" );
		$contents = "" if !defined $contents;
	}
	elsif( $name eq "a" )
	{
		if( $show_links )
		{
			my $href = $node->getAttribute( "href" );
			$contents .= " <$href>" if( defined $href );
		}
	}

	$$str .= $contents;

	return;
}

=item $page = $xhtml->page( $map, %opts )

Returns an EPrints::Page object describing an XHTML page filled out with the templates provided in $map.

$map is a hash of XHTML DOM fragments. At least "title" and "page" should be defined. Use "links" to add items to the header.

Option "page_id" set's the XML id of the <body> to be "page_YOURID". Useful when you want to use CSS to tweak elements on one page only.

Option "template" uses a different template to "default.xml".

=cut


sub page
{
	my( $self, $map, %options ) = @_;
	my $repo = $self->{repository};

	# if mainonly=yes is in effect return the page content
	if(
		$repo->get_online &&
		$repo->param( "mainonly" ) &&
		$repo->param( "mainonly" ) eq "yes"
	  )
	{
		if( defined $map->{'utf-8.page'} )
		{
			return EPrints::Page->new( $repo, $map->{'utf-8.page'}, add_doctype=>0 );
		}
		elsif( defined $map->{page} )
		{
			return EPrints::Page::DOM->new( $repo, $map->{page}, add_doctype=>0 );
		}
		else
		{
			EPrints->abort( "Can't generate mainonly without page" );
		}
	}

	# languages pin
	my $plugin = $repo->plugin( "Screen::SetLang" );
	if( defined $plugin )
	{
		$map->{languages} = $plugin->render_action_link;
	}
	
	$repo->run_trigger( EPrints::Const::EP_TRIGGER_DYNAMIC_TEMPLATE,
			pins => $map,
		);

	# we've been called by an older script
	if( !defined $map->{login_status} )
	{
		$map->{login_status} = EPrints::ScreenProcessor->new(
			session => $repo,
		)->render_toolbar;
	}

	if( defined $options{page_id} )
	{
		$map->{page_id} = $options{page_id};
	}

	if( $repo->get_online && $repo->config( 'allow_template_from_get' ) && defined $repo->param( "template" ) )
	{
		$options{template} = $repo->param( "template" );
	}

	if( !defined $options{template} )
	{
		$options{template} = "default";
	}

	my @output = @{ $repo->get_template_parts( 
				$repo->get_langid, 
				$options{template} ) };

	my $i = 0;
	foreach my $bit (@output)
	{
		next if $i++ % 2 == 0;

		# either 
		#  print:epscript-expr
		#  pin:id-of-a-pin
		#  pin:id-of-a-pin.textonly
		#  phrase:id-of-a-phrase
		my( $type, $rest ) = split /:/, $bit, 2;
		$bit = "";

		if( $type eq "print" )
		{
			my ( $pin, $pinid ) = split /:/, $rest, 2;
			my $frag = $repo->xml->create_document_fragment; 
			if ( $pin eq "pin" )
			{
				$frag = $repo->xml->create_text_node( $map->{$pinid} ) if defined $pinid && defined $map->{$pinid};
			}
			else 
			{
				$frag = EPrints::Script::print( $rest, { session=>$repo } );
			}
			$bit = $self->to_xhtml( $frag );
			$repo->xml->dispose( $frag );
		}

		elsif( $type eq "phrase" )
		{	
			my $phrase = $repo->html_phrase( $rest );
			$bit = $self->to_xhtml( $phrase );
			$repo->xml->dispose( $phrase );
		}

		elsif( $type eq "pin" )
		{	
			my( $pinid, $modifier ) = split /:/, $rest, 2;
			if( defined $modifier && $modifier eq "textonly" )
			{
				my $text;
				if( defined $map->{"utf-8.".$pinid.".textonly"} )
				{
					$text = $map->{"utf-8.".$pinid.".textonly"};
				}
				elsif( defined $map->{$pinid} )
				{
					# don't convert href's to <http://...>'s
					$text = $self->to_text_dump( $map->{$pinid},
						show_links => 0,
					);
				}

				if( defined $text )
				{
					# escape any entities in the text (<>&" etc.)
					my $xml = $repo->xml->create_text_node( $text );
					$bit = $repo->xml->to_string( $xml );
					$repo->xml->dispose( $xml );
				}
			}
			elsif( defined $map->{"utf-8.".$pinid} )
			{
				$bit = $map->{"utf-8.".$pinid};
			}
			elsif( defined $map->{$pinid} )
			{
				$bit = $self->to_xhtml( $map->{$pinid} );
			}
		}

		# otherwise this element is missing. Leave it blank.
	}

	return EPrints::Page->new( $repo, join( "", @output ) );
}

=item $node = $xhtml->tabs( $labels, $contents, %opts )

Render a tabbed box where:

 labels - an array of label XHTML fragments
 contents - an array of content XHTML fragments

Options:

 base_url - the link to follow under non-JS (default = current URL)
 basename - prefix for tab identifiers (default = "ep_tabs")
 current - index of tab to show first (default = 0)
 expensive - array of tabs to not javascript-link
 aliases - map tab index to alias name

=cut

sub tabs
{
	my( $self, $labels, $contents, %opts ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $online = $repo->get_online;

	my $base_url = exists($opts{base_url}) || !$online ? $opts{base_url} : $repo->current_url( query => 1 );
	my $basename = exists($opts{basename}) ? $opts{basename} : "ep_tabs";

	# compatibility with Session::render_tabs()
	my $aliases = $opts{aliases};
	my $links = $opts{links};

	# our special parameter
	my $q_current = $basename."_current";

	if( defined $base_url )
	{
		$base_url = URI->new( $base_url );
		# strip our parameter from the base URL
		my @q = $base_url->query_form;
		for(reverse 0..$#q)
		{
			next if $_ % 2;
			splice(@q, $_, 2) if $q[$_] eq $q_current;
		}
		$base_url->query_form( @q );
	}

	# render the current page according to the request (javascript might alter
	# the actual page shown)
	my $current = $opts{current};
	if( $online && defined($repo->param( $q_current )) )
	{
		$current = $repo->param( $q_current );
	}
	$current = 0 if !$current;
	if( defined $aliases )
	{
		my %raliases = reverse %$aliases;
		$current = exists $raliases{$current} ? $raliases{$current} : 0;
	}

	my $has_content = !!@$contents;

	my %expensive = map { $_ => 1 } @{$opts{expensive}||[]};

	my @tabs;

	for(0..$#$labels)
	{
		my $label = defined($aliases) ? $aliases->{$_} : $_;
		my $sanit_label = $label;
		$sanit_label =~ s/[^a-zA-Z0-9_-]/_/g;
		my $width = int( 100 / @$labels );
		$width += 100 % @$labels if $_ == 0;

		my $href;
		if( $online )
		{
			$href = $base_url->clone();
			$href->query_form(
				$href->query_form,
				$q_current => $label,
			);
		}
		if( defined $links && defined $links->{$label} )
		{
			$href = $links->{$label};
		}
		unless ( $href )
		{
			$href = "#";
		}

		my $tab = {};

		$tab->{tab_id} = $basename."_tab_".$sanit_label; 
		$tab->{panel_id} = $basename."_panel_".$sanit_label;
		$tab->{current} = $current == $_;
		$tab->{width} = $width;
		$tab->{label} = $labels->[$_];
		$tab->{href} = $href;
		$tab->{onclick} = "return ep_showTab('$basename','$label',".($expensive{$_}?1:0).");";

		if( $has_content )
		{
			$tab->{content} = $contents->[$_];
		}

		push @tabs, $tab;
	}

	return $repo->template_phrase( "view:EPrints/XHTML:tabs", { item => {
		basename => $basename,
		has_content => $has_content,
		tabs => \@tabs,
	} } );
}

=item $node = $xhtml->tree( $root, OPTIONS )
 
Render a tree using definition lists (DLs).

Options:

	prefix - id to use for the parent <div>
	class
		HTML class to use for div and prefix for open/close, defaults to
		'prefix' option
	render_value - custom renderer for values

=cut

sub tree
{
	my( $self, $root, %opts ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	$opts{class} = $opts{prefix} if !defined $opts{class};

	my $frag = $xml->create_document_fragment;

	$frag->appendChild( $xml->create_data_element( "div",
		$self->tree2( $root, %opts ),
		id => $opts{prefix},
		class => $opts{class},
	) );
	$frag->appendChild( $repo->make_javascript(<<"EOJ") );
window.onload = () => {
	ep_js_init_dl_tree('$opts{prefix}', '$opts{class}_open');
};
EOJ

	return $frag;
}

sub tree2
{
	my( $self, $root, %opts ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $frag = $xml->create_document_fragment;
	return $frag if !defined $root || !scalar(@$root);

	$opts{render_value} ||= sub { $xml->create_text_node( $_[0] ) };

	my $dl = $frag->appendChild( $xml->create_element( "dl" ) );
	
	foreach my $node (@$root)
	{
		if( ref($node) eq "ARRAY" )
		{
			my( $key, $children, %nopts ) = @$node;
	
			my %dt_attrs;
			my %dd_attrs;
			if ( ref($key) eq "EPrints::DataObj::Subject" ) 
			{
				my $subjectid = $key->get_id;
				$subjectid = EPrints::Utils::sanitise_element_id( $subjectid );
				$dt_attrs{id} = "ep_subj_title_" . $subjectid;
				$dd_attrs{id} = "ep_subj_desc_" . $subjectid;
			}

			$dl->appendChild( $xml->create_data_element( "dt",
				$opts{render_value}( @$node ),
				class => ($nopts{show} ? "$opts{class} $opts{class}_open" : $opts{class}),
				%dt_attrs,
			) );
			$dl->appendChild( $xml->create_data_element( "dd",
				$self->tree2( $children, %opts ),
				class => ($nopts{show} ? "" : "ep_no_js"),
				%dd_attrs,
			) );
		}
		else
		{
			$dl->appendChild( $xml->create_data_element( "dt",
				$opts{render_value}( $node ),
			) );
			$dl->appendChild( $xml->create_element( "dd",
				class => "ep_no_js",
			) );
		}
	}

	return $dl;
}

=item $node = $xhtml->action_list( $actions, %opts )

Returns an unordered list (<UL>) of actions on a single line. $actions is an array reference of XHTML fragments (e.g. icons or buttons).

=cut

sub action_list
{
	my( $self, $actions, %opts ) = @_;

	$self->{repository}->template_phrase( "view:EPrints/XHTML:action_list", { item => { actions => $actions, opts => \%opts } } );
}

=item $node = $xhtml->action_definition_list( $actions, $definitions, %opts )

Returns a definition list (<DL>) of actions plus their definitions. $actions is an array reference of XHTML fragments (e.g. icons or buttons).

=cut

sub action_definition_list
{
	my( $self, $actions, $definitions, %opts ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;

	my $list = [];

	for(my $i = 0; $i < @$actions; ++$i)
	{
		push @$list, {
			action => $actions->[$i],
			definition => $definitions->[$i],
		};
	}

	$repo->template_phrase( "view:EPrints/XHTML:action_definition_list", {
		item => {
			id => defined $opts{id} ? $opts{id} : "action_list",
			list => $list
		}
	});
}

=item $str = $xhtml->doc_type

Returns the default DOCTYPE as a string.

=cut

sub doc_type
{
	my( $self ) = @_;

	return <<'END';
<!DOCTYPE html>
END
}

######################################################################
=pod

=back

=cut
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

