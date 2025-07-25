=head1 NAME

EPrints::Plugin::Screen::Admin::Phrases

=cut

package EPrints::Plugin::Screen::Admin::Phrases;

@ISA = ( 'EPrints::Plugin::Screen' );

use Data::Dumper;

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
# See cfg.d/dynamic_template.pl
#		{
#			place => "key_tools",
#			position => 1350,
#			action => "edit",
#		},
		{ 
			place => "admin_actions_config", 
			position => 1350, 
		},
	];

	$self->{actions} = [qw( edit )];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/edit/phrase" );
}

sub allow_edit
{
	my( $self ) = @_;

	return
                !$self->{session}->{preparing_static_page} &&
                $self->can_be_viewed;
}
sub action_edit {} # dummy action for key_tools

sub wishes_to_export
{
	my( $self ) = @_;

	my $phraseid = $self->{session}->param( "phraseid" );
	return 0 unless defined $phraseid;
	
	return 1;
}

sub export
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $langid = $session->param( "lang" ) ? $session->param( "lang" ) : $session->get_langid;

	my( $message, $error_level ) = $self->write_phrase( $langid );	

	my $file = $session->config( "config_path" )."/lang/$langid/phrases/zz_webcfg.xml";

	my $phraseid = $session->param( "phraseid" );
	my $info = $session->get_language( $langid )->get_phrase_info( $phraseid, $session );
	my $phrase;
	my $src = "null";
	if( defined $info )
	{
		$src = $info->{system} ? "system" : "repo";
		$src .= $info->{fallback} ? "fallback" : "";
		$src = "webcfg" if $info->{filename} eq $file;
		$phrase = {
			phraseid => $phraseid,
			langid => $langid,
			src => $src,
			xml => $info->{xml},
		};
	}
	else
	{
		$phrase = {
			phraseid => $phraseid,
			langid => $langid,
			src => $src,
			xml => $session->make_doc_fragment
		};
	}

	my $row = $self->render_row( $phrase, $message, $error_level );

	binmode(STDOUT, ":utf8");
	print EPrints::XML::to_string( $row );

	EPrints::XML::dispose( $row );
}

sub write_phrase
{
	my( $self, $langid ) = @_;

	my $session = $self->{session};
	
	$langid ||= $session->get_langid;
	my $lang = $session->get_language( $langid );

	# get the phraseid to write
	my $phraseid = $session->param( "phraseid" );
	return unless defined $phraseid;
	my $phrase = $session->param( "phrase" );
	return unless defined $phrase;

	my $file = $session->config( "config_path" )."/lang/$langid/phrases/zz_webcfg.xml";

	my $info = $lang->get_phrase_info( $phraseid, $session );

	# if the phrase comes from zz_webcfg we don't need to reload config
	my $reload = 1;
	if( defined $info && $info->{filename} eq $file )
	{
		$reload = 0;
	}

	my $lib_path = $session->config( "lib_path" );

	# check the phrase is valid XML
	my $phrase_xml_str = "<?xml version='1.0' encoding='utf-8' standalone='no' ?>
<!DOCTYPE phrases SYSTEM '$lib_path/entities.dtd' >
<epp:phrase id='$phraseid' xmlns='http://www.w3.org/1999/xhtml' xmlns:epp='http://eprints.org/ep3/phrase' xmlns:epc='http://eprints.org/ep3/control'>".$phrase."</epp:phrase>\n\n";
	my $phrase_xml = eval { 
		my $doc = EPrints::XML::parse_xml_string( $phrase_xml_str );
		if( !defined $doc )
		{
			$@ = "XML parse error";
			return;
		}
		EPrints::XML::contents_of( $doc->getDocumentElement ); 
	};

	if( !defined $phrase_xml )
	{
		my $message_dom = $session->make_element( "div" );
		$message_dom->appendChild( $self->html_phrase( "write_failed" ) );
		my $pre = $session->make_element( "pre" );
		$message_dom->appendChild( $pre );
		$pre->appendChild( $session->make_text( $@ ) );
		return( $message_dom, "error" );
	}

	# create an empty webcfg phrases file, if it doesn't exist already
	if( !-e $file )
	{
		my $fh;
		unless( open( $fh, ">", $file ) )
		{
			my $message_dom = $session->make_element( "div" );
			$message_dom->appendChild( $session->html_phrase( 
				"problem_writing_file", 
				file => $session->make_text( $file ),
				error => $session->make_text( $! ) ) );
			return( $message_dom, "error" );
		}
		binmode($fh, ":utf8");
		print $fh <<END;
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<!DOCTYPE phrases SYSTEM "entities.dtd">
<epp:phrases xmlns="http://www.w3.org/1999/xhtml" xmlns:epp="http://eprints.org/ep3/phrase" xmlns:epc='http://eprints.org/ep3/control'>

</epp:phrases>
END
		close($fh);
	}

	my $doc = $session->get_repository->parse_xml( $file );
	my $remove_el;
	foreach my $phrase_el ( $doc->getElementsByTagNameNS("http://eprints.org/ep3/phrase","phrase" ) )
	{
		my $id = $phrase_el->getAttribute( "id" );
		if( $id eq $phraseid )
		{
			$remove_el = $phrase_el;
			last;
		}	
	}

	my $phrase_el = $doc->createElement( "epp:phrase" );
	$phrase_el->setAttribute( "id", $phraseid );
	$phrase_el->appendChild( 
		EPrints::XML::clone_and_own( $phrase_xml, $doc, 1 ) );
	if( defined $remove_el )
	{
		$remove_el->parentNode->replaceChild( $phrase_el, $remove_el );
	}
	else
	{
		$doc->documentElement->appendChild( $doc->createTextNode( "    " ));
		$doc->documentElement->appendChild( $phrase_el );
		$doc->documentElement->appendChild( $doc->createTextNode( "\n\n" ));
	}

	my $fh;
	unless( open( $fh, ">", $file ) )
	{
		my $message_dom = $session->make_element( "div" );
		$message_dom->appendChild( $session->html_phrase( 
				"problem_writing_file", 
				file => $session->make_text( $file ),
				error => $session->make_text( $! ) ) );
		return( $message_dom, "error" );
	}
	binmode($fh, ":utf8");
	print $fh EPrints::XML::to_string( $doc );
	close $fh;

	my $message_dom = $session->make_element( "div" );
	$message_dom->appendChild( $self->html_phrase( "save_ok" ) );
	$message_dom->appendChild( $session->make_text( " " ) );

	# force a load of zz_webcfg.xml to get the new phrase
	$lang->load_phrases( $file );

	if( !$reload )
	{
		$message_dom->appendChild( $self->html_phrase( "reload_not_required" ) );
	}
	elsif( !$self->EPrints::Plugin::Screen::Admin::Reload::allow_reload_config )
	{
		$message_dom->appendChild( $self->html_phrase( "reload_required" ) );
	}
	else
	{
		$self->EPrints::Plugin::Screen::Admin::Reload::action_reload_config;
		$message_dom->appendChild( $self->html_phrase( "will_reload" ) );
	}

	return( $message_dom, "message" );
}


sub export_mimetype
{
	my( $self ) = @_;

	return "text/html";
}


sub render_style
{
	my( $self ) = @_;

	my $style = $self->{session}->make_element( "style", type=>"text/css" );
	my $base_url = $self->{session}->get_url( path => "static" );
	$style->appendChild( $self->{session}->make_text( <<END ) );
#ep_phraseedit_table {
	width: 100%;
	border-collapse: collapse;
	margin-top: 1em;
}
#ep_phraseedit_table tr {
/*	background-color: #ccf; */
	border-bottom: dashed 1px #88f;
}
#ep_phraseedit_table tr td {
	padding: 3px;
}
.ep_phraseedit_widget {
	cursor: text;
	min-height: 1em;
/*	overflow: auto; */
}
#ep_phraseedit_table textarea {
/*	overflow: hidden; */
}
.ep_phraseedit_widget, #ep_phraseedit_table textarea {
	font-family: monospace;
	font-size: 9pt;
	width: 98%;
	display: block;
	background-color: white;
	border: solid 1px #66c;
	padding: 3px;
}
.ep_phraseedit_ref {
	border: dashed 1px #c66;
}
.ep_phraseedit_null {
	background-color: #ccf;
}
.ep_phraseedit_webcfg {
	background-color: #99f;
}
#ep_phraseedit_table td input {
	font-size: 90%;
}
#ep_phraseedit_addbar
{
	border: 1px solid #88c;
	background: #e7e9f5 url($base_url/style/images/toolbox.png) repeat-x;
	padding: 8px;
	margin-bottom: 0.75em;
	margin-top: 0.25em;
}
END
	return $style;
}



# stop post requests redirecting to GETs
sub redirect_to_me_url
{
	my( $self ) = @_;

	return undef;
}

sub render_action_link
{
	my( $self, %opts ) = @_;

	my $uri = $self->{session}->current_url(
			scheme => "https",
			host => 1,
			query => 1,
		);
	$uri->query_form(
		$uri->query_form,
		edit_phrases => "yes"
	);

	$opts{uri} = $uri;
	$opts{link_title} = $self->{session}->html_phrase( "lib/session:edit_phrases" );
	return $self->SUPER::render_action_link( %opts );
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $file = $session->config( "config_path" )."/lang/".$session->get_langid."/phrases/zz_webcfg.xml";

	my $f = $session->make_doc_fragment;
	
	$f->appendChild( $self->render_style );

	$f->appendChild( $self->html_phrase( "intro" ) );

	if( !defined $self->{phrase_ids} )
	{
		# add new phrase only shown on actual plugin page.
		$f->appendChild( $self->render_new_phrase() );
	}

	my $ids_for_langs;
	if( defined $self->{phrase_ids} )
	{
		my @ids = sort { lc($a) cmp lc($b) } @{$self->{phrase_ids}};
		$ids_for_langs->{$session->get_langid} = \@ids;
	}
	else
	{
		# get all phrase ids, excluding fallbacks, and sort them
		# alphabetically
		foreach my $langid ( @{$session->config( 'languages' )} )
		{
			my @ids = sort { lc($a) cmp lc($b) } $session->get_language( $langid )->get_phrase_ids( 0 );
			$ids_for_langs->{$langid} = \@ids;
		}
	}

	my $ep_save_phrase = EPrints::Utils::js_string( $self->phrase( "save" ) );
	my $ep_reset_phrase = EPrints::Utils::js_string( $self->phrase( "reset" ) );
	my $ep_cancel_phrase = EPrints::Utils::js_string( $self->phrase( "cancel" ) );
	$f->appendChild( $session->make_javascript( <<EOJ ) );
var ep_phraseedit_phrases = {
	save: $ep_save_phrase,
	reset: $ep_reset_phrase,
	cancel: $ep_cancel_phrase
};
EOJ

	my $table = $session->make_element( "table", id=>"ep_phraseedit_table" );
	my $tr = $session->make_element( "tr" );
	$table->appendChild( $tr );
	for(qw( id phrase src ))
	{
		my $th = $session->make_element( "th" );
		$tr->appendChild( $th );
		$th->appendChild( $self->html_phrase( "table_header_$_" ) );
	}

	my $defined_rows = $session->make_doc_fragment;
	my $undefined_rows = $session->make_doc_fragment;
	my $fallback_rows = $session->make_doc_fragment;
	foreach my $langid ( keys %{ $ids_for_langs } )
	{
		my $ids = $ids_for_langs->{$langid};

		foreach my $phraseid ( @$ids )
		{
			my $info = $session->get_language( $langid )->get_phrase_info( $phraseid, $session );
			my $src = "null";
			if( defined $info && $info->{fallback} )
			{
				$src = $info->{system} ? "system" : "repo";
				$src .= "fallback";
				$src = "webcfg" if $info->{filename} eq $file;
				$fallback_rows->appendChild( $self->render_row(
					{
						phraseid => $phraseid,
						xml => $info->{xml},
						langid  => $info->{langid},
						src => $src,
					},
					undef,
					"message",
				) );
			}
			elsif( defined $info )
			{
				$src = $info->{system} ? "system" : "repo";
				$src = "webcfg" if $info->{filename} eq $file;
				$defined_rows->appendChild( $self->render_row(
					{
						phraseid => $phraseid,
						xml => $info->{xml},
						langid  => $info->{langid},
						src => $src,
					},
					undef,
					"message",
				) );
			}
			else
			{
				$undefined_rows->appendChild( $self->render_row( 
					{
						phraseid=>$phraseid,
						xml=>$session->make_doc_fragment,
						langid => $info->{langid},
						src => $src,
					}, 
					$self->html_phrase( "phrase_not_defined" ),
					"warning",
				 ) );
			}
		}
	}
	$table->appendChild( $undefined_rows );
	$table->appendChild( $fallback_rows );
	$table->appendChild( $defined_rows );
	$f->appendChild( $table );	

	return $f;
}

sub render_row
{
	my( $self, $phrase, $message, $error_level ) = @_;

	my $session = $self->{session};
	my $phraseid = $phrase->{phraseid};
	my $src = $phrase->{src};

	my $langid = $session->config( 'defaultlanguage' );
	if( defined $phrase->{langid} )
	{
		$langid = $phrase->{langid};
	}

	my $xml = $phrase->{xml};
	my %seen = ($phrase->{phraseid} => 1);
	while($xml->can( "hasAttribute" ) && $xml->hasAttribute( "ref" ))
	{
		my $info = $session->get_language( $langid )->get_phrase_info( $xml->getAttribute( "ref" ), $session );
		last if !defined $info;
		last if $seen{$info->{phraseid}};
		$seen{$info->{phraseid}} = 1;
		$xml = $info->{xml};
	}

	my $string = "";
	foreach my $node ($xml->childNodes)
	{
		$string .= EPrints::XML::to_string( $node );
	}

	my( $tr, $td, $div );

	$tr = $session->make_element( "tr", class => "ep_phraseedit_$src" );

	$td = $session->make_element( "td", id => "ep_lang_${langid}_phraseedit_${phraseid}__label" );
	$tr->appendChild( $td );
	$td->appendChild( $session->make_text( $phraseid ) );

	$td = $session->make_element( "td" );
	$tr->appendChild( $td );
	# any messages
	if( defined $message )
	{
		$div = $session->make_element( "div" );
		$td->appendChild( $div );
		$div->appendChild( $session->render_message( $error_level, $message, 0 ));
	}

	# phrase editing widget
	if ( defined $session->config( "csrf_token_salt" ) && defined $session->current_user )
        {
		my $csrf_token = $session->get_csrf_token();
		$div = $session->make_element( "div", id => "ep_lang_${langid}_phraseedit_${phraseid}", class => "ep_phraseedit_widget", onfocus => "ep_phraseedit_edit(this, ep_phraseedit_phrases, '$csrf_token');", tabindex => "0" );
	}
	else
	{	
		$div = $session->make_element( "div", id => "ep_lang_${langid}_phraseedit_${phraseid}", class => "ep_phraseedit_widget", onfocus => "ep_phraseedit_edit(this, ep_phraseedit_phrases);", tabindex => "0" );
	}
	if( $xml ne $phrase->{xml} )
	{
		$div->setAttribute( class => "ep_phraseedit_widget ep_phraseedit_ref" );
	}
	$td->appendChild( $div );
	$div->appendChild( $session->make_text( $string ) );

	$td = $session->make_element( "td" );
	$tr->appendChild( $td );
	$td->appendChild( $session->make_text( $langid . "/" . $phrase->{src} ) );

	return $tr;
}

sub render_new_phrase
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $f = $session->make_doc_fragment;
	
	my $add_div = $session->make_element( "div", id=>"ep_phraseedit_addbar" );
	my $form = $session->render_form( "get",
		$session->config( "rel_cgipath" )."/users/home" );
	$form->appendChild( $self->render_hidden_bits );
	$form->appendChild(
		$session->render_noenter_input_field( 
			size => "50",
			name => "ep_phraseedit_newid",
			style => "border: solid 1px #88c",
			id => "ep_phraseedit_newid",
			'aria-labelledby' => "ep_phraseedit_add" ));
	my $languages = $session->config( 'languages' );
	if ( scalar @$languages > 1 )
	{
		my $lang_labels = {};
		foreach my $lang ( @$languages )
		{
			$lang_labels->{$lang} = $session->phrase( "languages_typename_$lang" );
		}
		my $default_language = $session->config( 'defaultlanguage' );
		$default_language = $session->get_session_language( $session->{request} ) if $session->{request};
		$form->appendChild(
        		$session->render_option_list(
					name => "ep_phraseedit_newlang",
					height => 1,
					multiple => 0,
					id => "ep_phraseedit_newlang",
					values => $languages,
					labels => $lang_labels,
					default =>  $default_language,
					'aria-labelledby' => "ep_phraseedit_add" ));	
	}
	$form->appendChild( $session->make_text( " " ) );
	my $csrf_token = "";
	if ( defined $session->config( "csrf_token_salt" ) && defined $session->current_user )
	{
		$csrf_token = $session->get_csrf_token();
	}
	$form->appendChild(
		$session->make_element( 
			"input", 
			class => "ep_form_action_button",
			role => "button",
			type => "submit", 
			value => $self->phrase( "new_phrase" ),
			id => "ep_phraseedit_add",
			onclick => "return ep_phraseedit_addphrase(event,document.getElementById('ep_phraseedit_newid').value,'$csrf_token')",
		)
	);
	$f->appendChild( $add_div );
	$add_div->appendChild( $form );

	return $f;
}

######################################################################
=pod


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

