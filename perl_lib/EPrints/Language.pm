######################################################################
#
# EPrints::Language
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::Language> - A single language supported by a repository.

=head1 DESCRIPTION

The language class handles loading the C<phrase> files for a single
language. See the mail documentation for a full explanation of the
format of phrase files.

=head1 METHODS

=over 4

=cut

######################################################################
#
# INSTANCE VARIABLES:
#
#  $self->{id}
#     The ISO id of this language.
#
#  $self->{fallback}
#     If $self is the primary language in its repository then this is
#     undef, otherwise it is a reference to the primary language
#     object.
#
#  $self->{repository_data}
#  $self->{data}
#     A reference to a hash. Keys are ids for phrases, values are
#     DOM fragments containing the phases.
#     repository_data contains repository specific phrases, data contains
#     generic eprints phrases.
#
#  $self->{xmldoc}
#     A XML document to hold all the stray DOM elements.
#
######################################################################

package EPrints::Language;

use strict;

######################################################################
=pod

=item $language = EPrints::Language->new( $langid, $repository, [$fallback] )

Create a new language object representing the phases eprints will
use in a given language, loading them from the phrase config XML files.

$langid is the ISO language ID of the language, $repository is the
repository to which this language object belongs. $fallback is either
undef or a reference to the main language object for the repository.

=cut
######################################################################

my %SYSTEM_PHRASES;

sub new
{
	my( $class , $langid , $repository , $fallback ) = @_;

	my $self = {};
	bless $self, $class;

	$self->{repository} = $repository;
	Scalar::Util::weaken( $self->{repository} )
		if defined &Scalar::Util::weaken;

	$self->{xmldoc} = EPrints::XML::make_document();

	$self->{id} = $langid;
	
	$self->{fallback} = $fallback;

	$self->{repository_data} = { docs => {} }; ## repository level phrases

	$self->{data} = $SYSTEM_PHRASES{$langid} ||= { docs => {} };  ## system level phrases

	my @lib_order = EPrints::Init::get_lib_paths( $repository->get_load_order, 'lang/' . $self->{id} . '/phrases' );

	foreach ( @lib_order )
	{
		if( -e $_ )
		{
			$self->_read_phrases_dir( $self->{repository_data}, $_ );
		}
	}

	return( $self );
}

sub CLONE
{
	my( $class ) = @_;

	%SYSTEM_PHRASES = ();
}

sub _read_phrases_dir
{
	my( $self, $data, $dir ) = @_;

	my $dh;
	# directory doesn't exist, so there won't be any files to read
	return if !opendir( $dh, $dir );
	foreach my $fn (sort readdir( $dh ) )
	{
		next if $fn =~ m/^\./;
		next unless $fn =~ m/\.xml$/;
		my $file = "$dir/$fn";
		if( !exists $data->{docs}->{$file} )
		{
			$self->_read_phrases( $data, $file );
		}
	}
	closedir $dh;
}

######################################################################
=pod

=item $info = $lang->get_phrase_info( $phraseid )

Returns a hash reference describing the phrase C<$phraseid>. Contains:

	langid - the language the phrase is from
	phraseid - the phrase id
	xml - the raw XML fragment
	fallback - whether the phrase was from the fallback language
	system - whether the phrase was from a system file
	filename - the file from which the phrase came

If C<$phraseid> does not exist returns C<undef>.

=cut
######################################################################

sub get_phrase_info
{
	my( $self, $phraseid ) = @_;

	my( $xml, $fb, $src, $file ) = $self->_get_phrase( $phraseid );
	return undef unless defined $xml;

	return {
		langid => ($fb ? $self->{fallback}->{id} : $self->{id}),
		phraseid => $phraseid,
		xml => $xml,
		filename => $file,
		fallback => $fb,
		system => ($src eq "data" ? 1 : 0),
	};
}

######################################################################
=pod

=item $phraseids = $language->get_phrase_ids( $fallback )

Returns an array reference of all phrase ids that are defined in this
language (i.e. repository and system).

If C<$fallback> is C<true> returns any additional phrase ids defined
in the fallback language.

=cut
######################################################################

sub get_phrase_ids
{
	my( $self, $fallback ) = @_;

	my %phrase_ids;

	foreach my $src (qw( data repository_data ))
	{
		for(keys %{$self->{$src}->{xml}})
		{
			$phrase_ids{$_} = undef;
		}
		if( $fallback && defined $self->{fallback} )
		{
			for(keys %{$self->{fallback}->{$src}->{xml}})
			{
				$phrase_ids{$_} = undef;
			}
		}
	}

	return keys %phrase_ids;
}

######################################################################
=pod

=item $xhtml = $language->phrase( $phraseid, $inserts )

Returns a XHTML DOM structure for the phrase with the given C<phraseid>.

C<$phraseid> is looked for in the following order, if it is not in one
phrase file the system checks the next.

=over 4

=item This language's repository specific phrases.

=item The fallback language's repository specific phrases (if there is a
fallback).

=item This language's general phrases.

=item The fallback language's general phrases (if there is a fallback).

=back

If C<$phraseid> is not found then a XHTML DOM object encpasulating an
appropriate error message is returned.

If the phrase contains C<pin> elements then C<$inserts> must be a hash
reference. Each C<pin> has a C<name> attribute. For each C<pin> there
must be a key in C<$inserts> of the C<name> whose value is a XHTML DOM
object which will replace the C<pin> in the returned phrase.

=cut
######################################################################

sub phrase
{
	my( $self, $phraseid, $inserts ) = @_;

	return $self->phrase_with_item( $phraseid, $inserts );
}

sub phrase_with_item
{
	my( $self, $phraseid, $inserts, $item ) = @_;

	my $session = $self->{repository};

	# not using fb
	my( $phrase , $fb ) = $self->_get_phrase( $phraseid );

	$inserts = {} if( !defined $inserts );
	if( !defined $phrase )
	{
		$session->get_repository->log( sprintf("Undefined phrase: %s (%s) at line %d in %s",
			$phraseid,
			$self->{id},
			(caller(1))[2,1] ) );
		my $frag = $session->make_doc_fragment;
		$frag->appendChild( $session->make_text( "['".$phraseid."' not defined" ) );
		if( scalar(keys %$inserts) )
		{
			my $dl = $session->make_element( "dl", class => "ep_undefined_phrase"  );
			$frag->appendChild( $dl );
			while(my( $key, $insert ) = each %$inserts)
			{
				my $dt = $session->make_element( "dt" );
				$dl->appendChild( $dt );
				$dt->appendChild( $session->make_text( $key ) );
				my $dd = $session->make_element( "dd" );
				$dl->appendChild( $dd );
				$dd->appendChild( $insert );
			}
		}
		$frag->appendChild( $session->make_text( ']' ) );
		return $frag;
	}

	# use referenced phrase instead
	my $ref = $phrase->getAttribute( "ref" );
	if( EPrints::Utils::is_set( $ref ) )
	{
		return $self->phrase_with_item( $ref, $inserts, $session, $item );
	}

#print STDERR "---\nN:$phrase\nNO:".$phrase->getOwnerDocument."\n";
	my $used = {};
	my $result = EPrints::XML::EPC::process_child_nodes( 
		$phrase, 
		in => "Phrase: '$phraseid'",
		session => $session,
		item => $item,
		pindata=>{ 
			inserts => $inserts,
			used => $used,
			phraseid => $phraseid,
		} );
	foreach( keys %{$inserts} )
	{
		if( !$used->{$_} )
		{
			# Should log this, but sometimes it's supposed to happen!
			# $session->get_repository->log( "Unused parameter \"$_\" passed to phrase \"$phraseid\"" );
			EPrints::XML::dispose( $inserts->{$_} );
		}
	}
	return $result;
}


######################################################################
#
# ( $phrasexml, $is_fallback ) = $language->_get_phrase( $phraseid )
#
# Return the phrase for the given id or undef if no phrase is defined,
# and reload the phrase from disk if needed.
#
######################################################################

sub _get_phrase
{
	my( $self, $phraseid ) = @_;

	# Look for the phrase in this order:
	# $self->{repository_data}, $self->{$data},
	# $fallback->{repository_data}, $fallback->{$data}
	foreach my $lang ($self, $self->{fallback})
	{
		next if !defined $lang;
		foreach my $src (qw( repository_data data ))
		{
			my( $xml, $file ) = $lang->_get_src_phrase( $src, $phraseid );
			# phrase, fallback?, source, XML file
			return( $xml, $lang ne $self, $src, $file ) if defined $xml;
		}
	}

	return ();
}

sub _get_src_phrase
{
	my( $self, $src, $phraseid ) = @_;

	my $session = $self->{repository};

	my $data = $self->{$src};

	my $xml = $data->{xml}->{$phraseid};
	return undef unless defined $xml;

	# Check the file modification time, reload it if it's changed
	my $file = ${$data->{file}->{$phraseid}};
	if( !defined( $session->{config_file_mtime_checked}->{$file} ) )
	{
		my $mtime = $data->{docs}->{$file}->{mtime};
		my $c_mtime = (stat( $file ))[9];
		if( $mtime ne $c_mtime )
		{
			$self->_reload_phrases( $data, $file );
			$xml = $data->{xml}->{$phraseid};
		}
		$session->{config_file_mtime_checked}->{$file} = 1;
	}

	return ($xml, $file);
}

######################################################################
=pod

=item $boolean = $language->has_phrase( $phraseid )

Returns C<1> if C<$phraseid> is defined for this language. Returns
C<0> if it is only available as a fallback or unavailable.

=cut
######################################################################

sub has_phrase
{
	my( $self, $phraseid ) = @_;

	my( $phrase , $fb ) = $self->_get_phrase( $phraseid );

	return( defined $phrase && !$fb );
}

######################################################################
=pod

=item $boolean = $language->has_non_empty_phrase( $phraseid )

Returns C<1> if C<$phraseid> is defined for this language and is not
an empty string. Returns C<0> if it is an empty string, only available
as a fallback or unavailable.

=cut
######################################################################

sub has_non_empty_phrase
{
	my( $self, $phraseid ) = @_;

	my( $phrase , $fb ) = $self->_get_phrase( $phraseid );

	my $text = "";
	if ( defined $phrase )
	{
		$text = EPrints::Utils::tree_to_utf8( $phrase );
	}

	return( $text && !$fb );
}

######################################################################
#
# $foo = $language->_get_data
#
# undocumented
#
######################################################################

sub _get_data
{
	my( $self ) = @_;
	return $self->{data};
}

######################################################################
#
# $foo = $language->_get_repositorydata
#
# undocumented
#
######################################################################

sub _get_repositorydata
{
	my( $self ) = @_;
	return $self->{repository_data};
}


######################################################################
#
#  $phrases = $language->_read_phrases( $data, $file )
#
# Return a reference to a hash of DOM objects describing the phrases
# from the XML phrase file $file.
#
######################################################################

sub _read_phrases
{
	my( $self, $data, $file ) = @_;

	my $repository = $self->{repository};

	my $doc = $repository->parse_xml( $file );	
	if( !defined $doc )
	{
		print STDERR "Error loading $file\n";
		return;
	}
	my $phrases = ($doc->getElementsByTagName( "phrases" ))[0];

	if( !defined $phrases )
	{
		print STDERR "Error parsing $file\nCan't find top level element.\n";
		EPrints::XML::dispose( $doc );
		return;
	}

	# Keep the document in scope and record its mtime	
	my $mtime = (stat( $file ))[9];
	$data->{docs}->{$file} = {
		doc => $doc,
		mtime => $mtime,
	};

	my $warned = 1; # set to zero if we want to warn about name="" vs id=""
	my $near;
	foreach my $element ( $phrases->getChildNodes )
	{
		my $name = $element->nodeName;
		if( $name ne "phrase" and $name ne "epp:phrase" )
		{
			next;
		}
		my $key = $element->getAttribute( "id" );
		if( !defined $key || $key eq "")
		{
			$key = $element->getAttribute( "name" );
			if(  !$key || $key eq "" || !$warned )
			{
				my $warning = "Warning: in $file";
				if( defined $near )
				{
					$warning.=", near '$near'";
				}
				$warning.= " found phrase without 'id' attribute.";
				if( !$key || $key eq "")
				{
					$repository->log( $warning );
					next;
				}
				$repository->log(
						"$warning The phrase did have a 'name' attribute so this probably means it's an EPrints v2 phrase file." );
				$warned = 1;
			}
		}
		$near = $key;
		$data->{xml}->{$key} = $element;
		$data->{file}->{$key} = \$file; # save some memory
	}

	return $data;
}

######################################################################
#
#  $phrases = $language->_reload_phrases( $data, $file )
#
# Reload the phrases file $file (otherwise same as _read_phrases).
#
######################################################################

sub _reload_phrases
{
	my( $self, $data, $file ) = @_;

	# Find and remove all phrases read from this file
	foreach my $phraseid (keys %{$data->{xml}})
	{
		if( ${$data->{file}->{$phraseid}} eq $file )
		{
			delete $data->{xml}->{$phraseid};
			delete $data->{file}->{$phraseid};
		}
	}

	# Dispose of the old document
	my $doc = delete $data->{docs}->{$file};
	if( defined $doc )
	{
		EPrints::XML::dispose( $doc->{doc} );
	}
	else
	{
		$self->{repository}->log( "Asked to reload phrases file '$file', but it wasn't loaded already?" );
	}

	return $self->_read_phrases( $data, $file );
}


######################################################################
=pod

=item $langid = $language->get_id

Return the ISO 639 language ID of this language.

=cut
######################################################################

sub get_id
{
	my( $self ) = @_;
	return $self->{id};
}


######################################################################
=pod

=item $fallback_lang = $language->get_fallback()

Returns the fallback language for this language. Returns C<undef> if
there is no fallback.

=cut
######################################################################

sub get_fallback
{
	my( $self ) = @_;
	return $self->{fallback};
}


######################################################################
=pod

=item $ok = $language->load_phrases( $file )

Load phrases from C<$file> into the current language.

=cut
######################################################################

sub load_phrases
{
	my( $self, $file ) = @_;

	return unless -r $file;

	return $self->_reload_phrases( $self->{repository_data}, $file );
}


######################################################################
=pod

=item $doc = EPrints::Language->create_phrase_doc( $session, [ $comment ] )

Returns a new, empty, phrases document. Optionally puts C<$comment> at
the top.

=cut
######################################################################

sub create_phrase_doc
{
	my( $class, $session, $comment ) = @_;

	my $xml = <<END;
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<!DOCTYPE phrases SYSTEM "entities.dtd">
<epp:phrases xmlns="http://www.w3.org/1999/xhtml" xmlns:epp="http://eprints.org/ep3/phrase" xmlns:epc='http://eprints.org/ep3/control'>

</epp:phrases>
END

	my $doc = EPrints::XML::parse_xml_string( $xml );

	if( defined $comment )
	{
		my $phrases = $doc->documentElement;
		$phrases->appendChild( $doc->createComment( $comment ) );
		$phrases->appendChild( $doc->createTextNode( "\n\n" ) );
	}

	return $doc;
}

1;

######################################################################
=pod

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

