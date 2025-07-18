######################################################################
#
# EPrints::Script::Compiled
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::Script::Compiled> - Namespace for EPrints::Script functions.

=cut

package EPrints::Script::Compiled;

use Time::Local 'timelocal_nocheck';

use strict;

sub debug
{
	my( $self, $depth ) = @_;

	$depth = $depth || 0;
	my $r = "";

	$r.= "  "x$depth;
	$r.= $self->{id};
	if( defined $self->{value} ) { $r.= " (".$self->{value}.")"; }
	if( defined $self->{pos} ) { $r.= "   #".$self->{pos}; }
	$r.= "\n";
	foreach( @{$self->{params}} )
	{
		$r.=debug( $_, $depth+1 );
	}
	return $r;
}

sub run
{
	my( $self, $state ) = @_;

	if( !defined $self->{id} ) 
	{
		$self->runtime_error( "No ID in tree node" );
	}

	if( $self->{id} eq "INTEGER" )
	{
		return [ $self->{value}, "INTEGER" ];
	}
	if( $self->{id} eq "STRING" )
	{
		return [ $self->{value}, "STRING" ];
	}

	if( $self->{id} eq "VAR" )
	{
		if( !exists $state->{$self->{value}} )
		{
			$self->runtime_error( "Unknown state variable '".$self->{value}."'" );
		}
		my $r = $state->{$self->{value}};
		return $r if( ref( $r ) eq "ARRAY" );
		return [ $r ];
	}

	my @params;
	foreach my $param ( @{$self->{params}} ) 
	{ 
		my $p = $param->run( $state ); 
		push @params, $p;
	}

	my $fn = "run_".$self->{id};

        if( !defined $EPrints::Script::Compiled::{$fn} )
        {
		$self->runtime_error( "call to unknown function: ".$self->{id} );
                next;
        }

	no strict "refs";
	my $result = $self->$fn( $state, @params );
	use strict "refs";

	return $result;
}

sub runtime_error 
{ 
	my( $self, $msg ) = @_;

	EPrints::Script::error( $msg, $self->{in}, $self->{pos}, $self->{code} )
}

sub run_LESS_THAN
{
	my( $self, $state, $left, $right ) = @_;

	if( ref( $left->[1] ) eq "EPrints::MetaField::Date" || ref( $left->[1] ) eq "EPrints::MetaField::Time" || $left->[1] eq "DATE" )
	{
		return [ ($left->[0]||"0000") lt ($right->[0]||"0000"), "BOOLEAN" ];
	}
	
	return [ $left->[0] < $right->[0], "BOOLEAN" ];
}

sub run_GREATER_THAN
{
	my( $self, $state, $left, $right ) = @_;

	if( ref( $left->[1] ) eq "EPrints::MetaField::Date" || ref( $left->[1] ) eq "EPrints::MetaField::Time" || $left->[1] eq "DATE" )
	{
		return [ ($left->[0]||"0000") gt ($right->[0]||"0000"), "BOOLEAN" ];
	}
	
	return [ $left->[0] > $right->[0], "BOOLEAN" ];
}

sub run_EQUALS
{
	my( $self, $state, $left, $right ) = @_;

	if( $right->[1]->isa("EPrints::MetaField") && $right->[1]->{multiple} )
	{
		foreach( @{$right->[0]} )
		{
			return [ 1, "BOOLEAN" ] if( $_ eq $left->[0] );
		}
		return [ 0, "BOOLEAN" ];
	}
	
	if( $left->[1]->isa( "EPrints::MetaField") && $left->[1]->{multiple} )
	{
		foreach( @{$left->[0]} )
		{
			return [ 1, "BOOLEAN" ] if( $_ eq $right->[0] );
		}
		return [ 0, "BOOLEAN" ];
	}
	my $l = $left->[0];
	$l = "" if( !defined $l );
	my $r = $right->[0];
	$r = "" if( !defined $r );
	
	return [ $l eq $r, "BOOLEAN" ];
}

sub run_NOTEQUALS
{
	my( $self, $state, $left, $right ) = @_;

	my $r = $self->run_EQUALS( $state, $left, $right );
	
	return $self->run_NOT( $state, $r );
}

sub run_ADD
{
	my( $self, $state, $left, $right ) = @_;

	return [ $left->[0] + $right->[0], "INTEGER" ];
}
sub run_SUBTRACT
{
	my( $self, $state, $left, $right ) = @_;

	return [ $left->[0] - $right->[0], "INTEGER" ];
}

sub run_MULTIPLY
{
	my( $self, $state, $left, $right ) = @_;

	return [ $left->[0] * $right->[0], "INTEGER" ];
}
sub run_DIVIDE
{
	my( $self, $state, $left, $right ) = @_;

	return [ int($left->[0] / $right->[0]), "INTEGER" ];
}

sub run_MOD
{
	my( $self, $state, $left, $right ) = @_;

	return [ $left->[0] % $right->[0], "INTEGER" ];
}

sub run_NOT
{
	my( $self, $state, $left ) = @_;

	return [ !$left->[0], "BOOLEAN" ];
}

sub run_UMINUS
{
	my( $self, $state, $left ) = @_;

	return [ -$left->[0], "INTEGER" ];
}

sub run_AND
{
	my( $self, $state, $left, $right ) = @_;
	
	return [ $left->[0] && $right->[0], "BOOLEAN" ];
}

sub run_OR
{
	my( $self, $state, $left, $right ) = @_;
	
	return [ $left->[0] || $right->[0], "BOOLEAN" ];
}

sub run_PROPERTY
{
	my( $self, $state, $objvar ) = @_;

	return $self->run_property( $state, $objvar, [ $self->{value}, "STRING" ] );
}

sub run_property 
{
	my( $self, $state, $objvar, $value ) = @_;

	if( !defined $objvar->[0] )
	{
		$self->runtime_error( "can't get a property {".$value->[0]."} from undefined value" );
	}

	# allow temporary strings values stashed on the object to be accessed by the script
	if( $value->[0] =~ /^tmp__/ && defined $objvar->[0]->{ $value->[0] } )
	{
		return [ $objvar->[0]->{ $value->[0] } , "STRING" ]
	}

	my $ref = ref($objvar->[0]);
	if( $ref eq "HASH" || $ref eq "EPrints::RepositoryConfig" )
	{
		my $v = $objvar->[0]->{ $value->[0] };
		my $type = ref( $v ) =~ /^XML::/ ? "XHTML" : "STRING";
		return [ $v, $type ];
	}
	if( $ref !~ m/::/ )
	{
		$self->runtime_error( "can't get a property from anything except a hash or object: ".$value->[0]." (it was '$ref')." );
	}
	if( !$objvar->[0]->isa( "EPrints::DataObj" ) )
	{
		$self->runtime_error( "can't get a property from non-dataobj: ".$value->[0] );
	}
	if( !$objvar->[0]->get_dataset->has_field( $value->[0] ) )
	{
		$self->runtime_error( $objvar->[0]->get_dataset->confid . " object does not have a '".$value->[0]."' field" );
	}

	return [ 
		$objvar->[0]->get_value( $value->[0] ),
		$objvar->[0]->get_dataset->get_field( $value->[0] ),
		$objvar->[0] ];
}

sub run_MAIN_ITEM_PROPERTY
{
	my( $self, $state ) = @_;

	return run_PROPERTY( $self, $state, [$state->{item}] );
}

sub run_reverse
{
	my( $self, $state, $string ) = @_;

	return [ reverse $string->[0], "STRING" ];
} 

sub run_substr
{
        my( $self, $state, $string, $offset, $length ) = @_;

        return [ substr( $string->[0], $offset->[0], $length->[0]), "STRING" ];
}
	
# run_contains tests if string has a substring of token
sub run_contains
{
        my( $self, $state, $string, $token, $length ) = @_;
        my $t = $token->[0];

        return [ $string->[0] =~ /$t/, "BOOLEAN" ];
}

sub run_is_set
{
	my( $self, $state, $param ) = @_;

	return [ EPrints::Utils::is_set( $param->[0] ), "BOOLEAN" ];
} 

sub run_citation_link
{
	my( $self, $state, $object, $citationid ) = @_;

	my $citation = $object->[0]->render_citation_link( $citationid->[0]  );

	return [ $citation, "XHTML" ];
}

sub run_embed_video
{
        my( $self, $state, $object ) = @_;

        if( !$object->[0]->isa( "EPrints::DataObj::Document" ) )
        {
                $self->runtime_error( "can't call embed_vidio on non-document objects." );
        }

        my $xhtml = $object->[0]->render_video_preview( "ep_embedded_video" );

        return [ $xhtml, "XHTML" ];
}

sub run_citation
{
	my( $self, $state, $object, $citationid ) = @_;

	my $citation = $object->[0]->render_citation( $citationid->[0],
		finalize => 0
	);

	return [ $citation, "XHTML" ];
}

sub run_yesno
{
	my( $self, $state, $left ) = @_;

	if( $left->[0] )
	{
		return [ "yes", "STRING" ];
	}

	return [ "no", "STRING" ];
}

sub run_if
{
	my( $self, $state, $condition, $true_expr, $false_expr ) = @_;
	
	my $test = $condition->[0];

	if( !$test && !defined( $false_expr ))
	{
		return [ "", "STRING" ];
	}

	return [
		$test ? $true_expr->[0] : $false_expr->[0],
		$test ? $true_expr->[1] : $false_expr->[1]
	];	
}


=item one_of( VAR, ARRAY )

Returns true if VAR is in ARRAY.  ARRAY can be passed as an array ref
or a list of arguments, e.g., $var.one_of( $arrayref ) or
$var.one_of( '1', '2', '3' )

=cut

sub run_one_of
{
	my( $self, $state, $left, @params ) = @_;

	if( !defined $left )
	{
		return [ 0, "BOOLEAN" ];
	}
	if( !defined $left->[0] )
	{
		return [ 0, "BOOLEAN" ];
	}

        my @list;
        # If @params is a single ARRAY element, expand the ARRAY to a
        # list of string elements and compare against each of those.
        if ( scalar @params == 1 && $params[0]->[1] eq 'ARRAY' )
        {
            @list = $self->_array_to_list( $params[0] );
        }
        else
        {
            # The params are the list to compare against
            @list = @params;
        }

	foreach( @list )
	{
		my $result = $self->run_EQUALS( $state, $left, $_ );
		return [ 1, "BOOLEAN" ] if( $result->[0] );
	}
	return [ 0, "BOOLEAN" ];
} 

#
# Converts a Perl ARRAY into a list of EPScript string literals and
# returns it.
#
# $array must be an array ref. Assumes that the items of $array are
# strings.
#
# Example:
# [ [ '1', '2', '3'], 'ARRAY' ]
#   converts to
# [ [ '1', 'STRING' ], [ '2', 'STRING' ], [ '3', 'STRING' ] ]
#
sub _array_to_list
{
    my( $self, $array ) = @_;

    my @new_list = ();
    foreach ( @{$array->[0]} )
    {
        push @new_list, [ $_, 'STRING' ];
    }
    return @new_list;
}

sub run_as_item 
{
	my( $self, $state, $itemref ) = @_;

	my $field = $itemref->[1];

	if(
		!UNIVERSAL::isa($field, "EPrints::MetaField::Itemref") &&
		!UNIVERSAL::isa($field, "EPrints::MetaField::Dataobjref")
	  )
	{
		$self->runtime_error( "as_item requires a itemref or dataobjref" );
	}

	my $object = $field->get_item( $state->{session}, $itemref->[0] );

	return [ $object ];
}

sub run_as_string
{
	my( $self, $state, $value ) = @_;

	return [ $value->[0], "STRING" ];
}

sub run_strlen
{
	my( $self, $state, $value ) = @_;

	if( !EPrints::Utils::is_set( $value->[0] ) )
	{
		return [0,"INTEGER"];
	}

	return [ length( $value->[0] ), "INTEGER" ];
}

sub run_length
{
	my( $self, $state, $value ) = @_;

	if( !EPrints::Utils::is_set( $value->[0] ) )
	{
		return [0,"INTEGER"];
	}
	
	if( $value->[1] eq "ARRAY" || $value->[1] eq "DATA_ARRAY" )
	{
		return [ scalar @{$value->[0]}, "INTEGER" ];
	}

	if( !$value->[1]->isa( "EPrints::MetaField" ) )
	{
		return [1,"INTEGER"];
	}

	if( !$value->[1]->get_property( "multiple" ) ) 
	{
		return [1,"INTEGER"];
	}

	# multiple metafield
	return [ scalar @{$value->[0]}, "INTEGER" ];
}

sub run_today
{
	my( $self, $state ) = @_;

	return [EPrints::Time::get_iso_date, "DATE"];
}

sub run_datemath
{
	my( $self, $state, $date, $alter, $type ) = @_;

	my( $year, $month, $day ) = split( "-", $date->[0] );

	if( $type->[0] eq "day" )
	{
		$day+=$alter->[0];
	}
	elsif( $type->[0] eq "month" )
	{
		$month+=$alter->[0];
		while( $month < 1 )
		{
			$year--;
			$month += 12;
		}
		while( $month > 12 )
		{
			$year++;
			$month -= 12;
		}
		
	}
	elsif( $type->[0] eq "year" )
	{
		$year+=$alter->[0];
	}
	else
	{
		return [ "DATE ERROR: Unknown part '".$type->[0]."'", "STRING" ];
	}

        my $t = timelocal_nocheck( 0,0,0,$day,$month-1,$year-1900 );

	return [ EPrints::Time::get_iso_date( $t ), "DATE" ];
}

sub run_dataset 
{
	my( $self, $state, $object ) = @_;

	if( !$object->[0]->isa( "EPrints::DataObj" ) )
	{
		$self->runtime_error( "can't call dataset on non-data objects." );
	}

	return [ $object->[0]->get_dataset->confid, "STRING" ];
}

sub run_related_objects
{
	my( $self, $state, $object, @required ) = @_;

	if( !defined $object->[0] || ref($object->[0])!~m/^EPrints::DataObj::/ )
	{
		$self->runtime_error( "can't call dataset on non-data objects." );
	}

	my @r = ();
	foreach( @required ) { push @r, $_->[0]; }
	
	return [ scalar($object->[0]->get_related_objects( @r )), 'ARRAY' ];
}

sub run_url
{
	my( $self, $state, $object ) = @_;

	if( !defined $object->[0] || ref($object->[0])!~m/^EPrints::DataObj::/ )
	{
		$self->runtime_error( "can't call url() on non-data objects." );
	}

	return [ $object->[0]->get_url, "STRING" ];
}

sub run_doc_size
{
	my( $self, $state, $doc ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call doc_size() on document objects not ".
			ref($doc->[0]) );
	}

	if( !$doc->[0]->is_set( "main" ) )
	{
		# this must be an array ref so it can be passed to human_readable
		return [ 0, "INTEGER" ];
	}

	my %files = $doc->[0]->files;

	return [ $files{$doc->[0]->get_main} || 0, "INTEGER" ];
}

sub run_is_public
{
	my( $self, $state, $doc ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call is_public() on document objects not ".
			ref($doc->[0]) );
	}

	return [ $doc->[0]->is_public, "BOOLEAN" ];
}

sub run_thumbnail_url
{
	my( $self, $state, $doc, $size ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call thumbnail_url() on document objects not ".
			ref($doc->[0]) );
	}

	return [ $doc->[0]->thumbnail_url( $size->[0] ), "STRING" ];
}

sub run_preview_link
{
	my( $self, $state, $doc, $caption, $set, $size ) = @_;

	$size = defined $size ? $size->[0] : 'preview';

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call preview_link() on document objects not ".
			ref($doc->[0]) );
	}

	return [ $doc->[0]->render_preview_link( caption=>$caption->[0], set=>$set->[0], size=>$size ), "XHTML" ];
}

sub run_icon
{
	my( $self, $state, $doc, @opts ) = @_;

	if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
	{
		$self->runtime_error( "Can only call thumbnail_url() on document objects not ".
			ref($doc->[0]) );
	}

	my %args = ();
	foreach my $opt ( @opts )
	{
		my $optv = $opt->[0];
		if( $optv eq "HoverPreview" ) { $args{preview}=1; }
		elsif( $optv eq "noHoverPreview" ) { $args{preview}=0; }
		elsif( $optv eq "NewWindow" ) { $args{new_window}=1; }
		elsif( $optv eq "noNewWindow" ) { $args{new_window}=0; }
		elsif( $optv eq "previewLeft" ) { $args{preview_side}='left'; }
		elsif( $optv eq "previewRight" ) { $args{preview_side}='right'; }
		elsif( $optv eq "LargeIcon" ) { $args{size}='lightbox'; }
		elsif( $optv eq "noLink" ) { $args{with_link}=0; }
		else { $self->runtime_error( "Unknown option to doc->icon(): $optv" ); }
	}

	return [ $doc->[0]->render_icon_link( %args ), "XHTML" ];
}


sub run_human_filesize
{
	my( $self, $state, $size_in_bytes ) = @_;
	return [ EPrints::Utils::human_filesize( 0 ), "INTEGER" ] if not ($size_in_bytes); ##check if the $size_in_bytes is defined. (reduces warnings)
	return [ EPrints::Utils::human_filesize( $size_in_bytes->[0] || 0 ), "INTEGER" ];
}

sub run_control_url
{
	my( $self, $state, $eprint ) = @_;

	$eprint = $eprint->[0];

	if( !defined $eprint || !UNIVERSAL::can( $eprint, "get_control_url" ) )
	{
		$self->runtime_error( "Can only call control_url() on objects not ".
			ref($eprint) );
	}

	return [ $eprint->get_control_url(), "STRING" ];
}

sub run_js_string
{
	my( $self, $state, $string ) = @_;

	return [ EPrints::Utils::js_string( $string->[0] ), "STRING" ];
}

sub run_current_url
{
	my( $self, $state ) = @_;

	return [ $state->{session}->current_url( query => 0 ), "STRING" ];
}

sub run_contact_email
{
	my( $self, $state, $eprint, $doc ) = @_;

	if( !defined $eprint->[0] || ref($eprint->[0]) ne "EPrints::DataObj::EPrint" )
	{
		$self->runtime_error( "Can only call contact_email() on eprint objects not ".
			ref($eprint->[0]) );
	}

	if( !$state->{session}->get_repository->can_call( "email_for_doc_request" ) )
	{
		return [ undef, "STRING" ];
	}

	my $document = defined $doc && defined $doc->[0] ? $doc->[0] : undef;

	return [ $state->{session}->get_repository->call( "email_for_doc_request", $state->{session}, $eprint->[0], $document ), "STRING" ]; 
}

sub run_uri
{
	my( $self, $state, $dataobj ) = @_;

	return [ $dataobj->[0]->uri, "STRING" ];
}

# item is optional and it's primary key is passed to the list rendering bobbles
# for actions which need a current object.
sub run_action_list
{
	my( $self, $state, $list_id, $item ) = @_;

	my $screen_processor = EPrints::ScreenProcessor->new(
		session => $state->{session},
		screenid => "Error",
	);

	my $screen = $screen_processor->screen;
	$screen->properties_from;

	my @list = $screen->list_items( $list_id->[0], filter=>0 );
	if( defined $item )
	{
        	my $keyfield = $item->[0]->{dataset}->get_key_field();
		$screen_processor->{$keyfield->get_name()} = $item->[0]->get_id;
		foreach my $action ( @list )
		{
			$action->{hidden} = [$keyfield->get_name()];
		}
	}

	return [ \@list, "ARRAY" ];
}

sub run_action_button
{
	my( $self, $state, $action_p ) = @_;

	my $action = $action_p->[0]; 
	
	return [ $action->{screen}->render_action_button( $action ), "XHTML" ];
}
sub run_action_icon
{
	my( $self, $state, $action_p ) = @_;

	my $action = $action_p->[0]; 
	
	return [ $action->{screen}->render_action_icon( $action ), "XHTML" ];
}
sub run_action_description
{
	my( $self, $state, $action_p ) = @_;

	my $action = $action_p->[0]; 
	
	return [ $action->{screen}->get_description( $action ), "XHTML" ];
}

sub run_action_title
{
	my( $self, $state, $action_p ) = @_;

	my $action = $action_p->[0]; 
	
	if( defined $action->{action} )
	{
		return [ $action->{screen}->html_phrase( "action:".$action->{action}.":title" ), "XHTML" ];
	}
	else
	{
		return [ $action->{screen}->html_phrase( "title" ), "XHTML" ];
	}
}

sub run_filter_compound_list
{
	my( $self, $state, $compound_list, $filter_field, $filter_value, $print_field ) = @_;
	
	my $f = $compound_list->[1]->get_property( "fields_cache" );
	my $sub_field;
	foreach my $field_conf ( @{$f} )
	{
		if( $field_conf->{sub_name} eq $print_field->[0] )
		{
			$sub_field = $field_conf;
		}
	}
	if( !$sub_field )
	{
		$self->runtime_error( "No such sub field: ".$print_field->[0] );
	}
	my @r = ();
	if( !$compound_list->[1]->isa("EPrints::MetaField") )
	{
		$self->runtime_error( "1st param not eprints metadata" );
	}

	foreach my $item ( @{$compound_list->[0]} )
	{
		my $t = $item->{$filter_field->[0]} || "";
		if( $t eq $filter_value->[0] )
		{
			push @r, $item->{$print_field->[0]};
		}
	}

	return [ \@r, $sub_field ];
}


sub run_to_data_array
{
	my( $self, $state, $val ) = @_;

	if( !$val->[1]->isa("EPrints::MetaField") )
	{
		$self->runtime_error( "to_data_array expects a field value" );
	}

	my $field = $val->[1]->clone;
	$field->set_property( "multiple", 0 );
	my @v;
	foreach my $item ( @{$val->[0]} )
	{
		push @v, [ $item, $field ];
	}

	return [ \@v, "DATA_ARRAY" ];
}

sub run_pretty_list
{
	my( $self, $state, $list, $sep, $last_sep, $finally ) = @_;

	if( $list->[1]->isa("EPrints::MetaField") )
	{
		$list = $self->run_to_data_array( $state, $list );
	}

	if( $list->[1] ne "DATA_ARRAY" )
	{
		$self->runtime_error( "pretty list takes a Multiple Field or DATA_ARRAY" );
	}

	my $n = scalar @{$list->[0]};
	my $r = $state->{session}->make_doc_fragment;

	for( my $i=0; $i<$n; ++$i )
	{
		if( $i > 0 )
		{
			if( defined $last_sep && $i == $n-1 )
			{
				$r->appendChild( $state->{session}->make_text( $last_sep->[0] ) );
			}
			else
			{
				$r->appendChild( $state->{session}->make_text( $sep->[0] ) );
			}
		}
		my $val = $list->[0]->[$i]->[0];
		my $field = $list->[0]->[$i]->[1];
		$r->appendChild( 
			$field->render_value( $state->{session}, $val, 0, 0 ));
	}
	if( $n > 0 && defined $finally )
	{
		$r->appendChild( $state->{session}->make_text( $finally->[0] ) );
	}

	return [ $r, "XHTML" ];
}

sub run_array_concat
{
	my( $self, $state, @arrays ) = @_;

	my @v = ();
	foreach my $array ( @arrays )
	{
		if( $array->[1]->isa("EPrints::MetaField") )
		{
			$array = $self->run_to_data_array( $state, $array );
		}
	
		if( $array->[1] ne "DATA_ARRAY" )
		{
			$self->runtime_error( "array_concat takes a list of Multiple Field or DATA_ARRAYs" );
		}

		push @v, @{$array->[0]};
	}

	return [ \@v, "DATA_ARRAY" ];
}

sub run_array_length
{
	my( $self, $state, $array ) = @_;

	return [ scalar @{$array->[0]}, "INTEGER" ];
}

sub run_concat
{
	my( $self, $state, @strings ) = @_;

	return [ join('', map { $_->[0] } @strings ), "STRING" ];
}

sub run_join
{
	my( $self, $state, $array, $join_string ) = @_;

	my @list = ();
	if( $array->[1]->isa("EPrints::MetaField") )
	{
		my $data_array = $self->run_to_data_array( $state, $array );
		foreach my $item ( @{$data_array->[0]} )
		{
			push @list, $item->[0];
		}
	}
	elsif( ref( $array->[0] ) eq "ARRAY" )
	{
		@list = @{$array->[0]};
	}
	else
	{
		$self->runtime_error( "join() expects an array" );
	}

	return [ join( $join_string->[0], @list ), "STRING" ];
}

sub run_phrase
{
	my( $self, $state, $phrase ) = @_;

	return [ $state->{session}->html_phrase( $phrase->[0] ), "XHTML" ];
}

sub run_has_phrase
{
	my( $self, $state, $phrase ) = @_;

	return [ $state->{session}->get_lang->has_phrase( $phrase->[0], $state->{session} ), "INTEGER" ];
}

sub run_string_phrase
{
	my( $self, $state, $phrase ) = @_;

	return [ $state->{session}->phrase( $phrase->[0] ), "STRING" ];
}

sub run_text
{
	my( $self, $state, $phrase ) = @_;

	return [ $state->{session}->make_text( $phrase->[0] ), "XHTML" ];
}

sub run_documents
{
	my( $self, $state, $eprint ) = @_;

	if( ! $eprint->[0]->isa( "EPrints::DataObj::EPrint") )
	{
		$self->runtime_error( "documents() must be called on an eprint object." );
	}
	return [ [$eprint->[0]->get_all_documents()],  "ARRAY" ];
}

sub run_has_role
{
	my( $self, $state, $user, $role ) = @_;

	if(( ref $user->[0] ) ne "EPrints::DataObj::User" )
	{
		$self->runtime_error( "has_role can only be used on a user object" );
	}

	if( $role->[1] ne "STRING" )
	{
		$self->runtime_error( "role must be a string" );
	}

	my $has_role = $user->[0]->has_role( $role->[0] );

	return [ $has_role, "BOOLEAN" ];
}

=item OBJ.render_value_function( FUNC, FIELD[, EXTRA...] )

Extracts the value of the given FIELD from the OBJ data object, and renders
it using the callback FUNC.

FUNC must accept at least three parameters: $session, $field, and $value,
and return an XHTML DOM structure.

If EXTRAs are given, they will be passed to FUNC as the fourth, fifth, etc.
parameters.

=cut

sub run_render_value_function
{
	my( $self, $state, $dataobj, $funcname, $fieldname, @extra ) = @_;

	my( $value, $field ) = @{$self->run_property( $state, $dataobj, $fieldname )};

	no strict "refs";
	my $xhtml = $funcname->[0](
		$state->{session},
		$field,
		$value,
		map {$_->[0]} @extra
	);
	use strict "refs";

	return [ $xhtml, "XHTML" ];
}


=item {MF,VAR}.dumper()
Provides XHTML pre element containing the type and serialization of a metafield or variable.  Not useful for data objects, as dumper output will be too long to be rendered.
=cut

sub run_dumper
{
	my( $self, $state, $data ) = @_;

	use Data::Dumper;
	my $pre = $state->{session}->make_element( "pre" );
	$pre->appendChild( $state->{session}->make_text( "TYPE: ".ref($data->[0])."\nVALUE: ".Dumper( $data->[0] ) ) );
	
	return [ $pre , "XHTML" ];
}


=item OBJ.subproperty( VALUE )
Extracts the value of a specified subproperty of a compound (non-multiple only) metafield.
=cut

sub run_subproperty
{
	my( $self, $state, $objvar, $value, $pos ) = @_;

	if( !defined $objvar->[0] )
	{
		$self->runtime_error( "can't get a property {".$value->[0]."} from undefined value" );
	}
	my $ref = ref($objvar->[1]);

	if( $ref !~ m/::/ || ! $objvar->[1]->isa( "EPrints::MetaField::Compound" ) )
	{
		$self->runtime_error( "can't get a subproperty from anything except a compound field value, when trying to get ".$value->[0]." from a $ref" );
	}
	my $field = $objvar->[1];
	if( $field->get_property( "multiple" ) )
	{
		$self->runtime_error( "can't get a subproperty from a multiple field." );
	}
	
	my $fc = $field->get_property( "fields_cache" );
	my $sub_field;
	my @ok = ();
	foreach my $a_sub_field ( @{$fc} )
	{
		push @ok, $a_sub_field->{sub_name};
		if( $a_sub_field->{sub_name} eq $value->[0] )
		{
			$sub_field = $a_sub_field;
		}
	}
	if( !defined $sub_field ) {
		$self->runtime_error( "unknown sub-field of a compound: ".$value->[0].". OK values: ".join( ", ", @ok )."." );
	}

	return [
		$objvar->[0]->{ $value->[0] },
                 $sub_field ];
}


=item VAR.to_dataobj( DATASET, DATAOBJ_FIELDNAME )
Returns the data object determined by looking up the value of VAR against the DATAOBJ_FIELDNAME of the DATASET.
=cut

sub run_to_dataobj
{
	my( $self, $state, $objvar, $dataset, $dataobj_fieldname ) = @_;

	if( !defined $objvar || !defined $objvar->[0] ) {
		return [];
	}
	if( !defined $dataset || !defined $dataset->[0] ) {
                return [];
        }
	if( !defined $dataobj_fieldname || !defined $dataobj_fieldname->[0] ) {
                return [];
        }

	my $dataobj_fieldvalue = $objvar->[0];
	my $results = $state->{session}->dataset( $dataset->[0] )->search(	
		filters => [
			{
				meta_fields => [ $dataobj_fieldname->[0] ],
				value => $dataobj_fieldvalue,
				match => "EX"
			}
	]);
	my $dataobj = $results->item(0);

	return [$dataobj];
}

=item homepage_menu( )
Generates homepage's block menu from configuration in cfg.d/homepage.pl.
=cut

sub run_homepage_menu
{
	my( $self, $state ) = @_;

	my $session = $state->{session};
	my $hpmenu_conf = $session->config( 'homepage', 'menu' );	

	my $homepage_menu = $state->{session}->make_doc_fragment;
	my $nav = $session->make_element( 'nav', id => 'ep-homepage-menu', 'aria-label' => $session->phrase( 'homepage_menu_aria_label' ) );
	my $ul = $session->make_element( 'ul', class => "ep_block_menu", role => 'menu' );
	my @options = ();
	my @fulloptions = ();
	foreach my $option ( @{$hpmenu_conf->{options}} )
	{
		$fulloptions[$option->{appears}] = $option;
	}
 	foreach my $option ( @fulloptions )
	{
		push @options, $option if defined $option;
	}
	foreach my $option ( @options )
	{
		my $id = 'ep-hp-menu-opt-' . $option->{id};
		my $class = "ep_block_menu_option_";
		my $li = $session->make_element( 'li', id => $id, role => 'menuitem' );
		my $title = $session->make_element( 'p', class => $class . 'title', 'aria-described-by' => "$id-desc" );
		my $url = $option->{url};
		if ( $url =~ m!^/! )
		{
			$url = $session->config( 'rel_path' ) . $url;
		}
		my $title_link = $session->make_element( 'a', href => $url );
		$title_link->appendChild( $session->html_phrase( 'homepage_menu_option_' . $option->{id} . ':title' ) ) ;
		$title->appendChild( $title_link );
		$li->appendChild( $title );
		my $desc = $session->make_element( 'p', class => $class . 'desc', id => "$id-desc" );
		$desc->appendChild( $session->html_phrase( 'homepage_menu_option_' . $option->{id} . ':desc' ) ) ;
		$li->appendChild( $desc );
		$ul->appendChild( $li );

	}
	$nav->appendChild( $ul );
	$homepage_menu->appendChild( $nav );
	return [ $homepage_menu, "XHTML" ];
}

=item [$encoded, 'STRING'] = run_url_encode( $self, $state, $text )

Creates the C<url_encode> method which applies url encoding to the given string.

This is used by C<bundle_export> because it accesses local files via a browser so
if the files include things like backslashes, speech marks or double spaces it
would fail to open them.

=cut

sub run_url_encode
{
        my( $self, $state, $text ) = @_;

        my $encoded = URI::Escape::uri_escape_utf8(
                $text->[0],
                "^A-Za-z0-9\-\._~\/" # don't escape /
        );

        return [ $encoded, 'STRING' ];
}

=item [$boolean, 'BOOLEAN'] = run_current_user_can_view( $self, $state, $doc )

Creates the C<current_user_can_view> method which checks whether the current user
can view the given C<DataObj::Document>.

If there is no current user then it checks if the document is public.

This will always return C<true> if called from the command line.

=cut

sub run_current_user_can_view
{
        my( $self, $state, $doc ) = @_;

        my $session = $state->{session};

        if( !defined $doc->[0] || ref($doc->[0]) ne "EPrints::DataObj::Document" )
        {
                $self->runtime_error( "Can only call can_current_user_view() on Document objects not ". ref($doc->[0]) );
        }

        return [ 1, 'BOOLEAN' ] if !$session->is_online;
        return [ 1, 'BOOLEAN' ] if $doc->[0]->is_public;

        return [ defined $session->current_user && $doc->[0]->user_can_view( $session->current_user ), 'BOOLEAN' ];
}

=item [$boolean, 'BOOLEAN'] = run_variable_exists( $self, $state, $var_name )

Creates the C<variable_exists> method which checks whether the variable
referred to by the passed string exists.

This should be used in a separate C<test> block to anything using this
variable as anything in the block will be parsed before calling functions.

=cut

sub run_variable_exists
{
	my( $self, $state, $var_name ) = @_;

	if( $state->{$var_name->[0]} ) {
		return [ 1, 'BOOLEAN' ];
	} else {
		return [ 0, 'BOOLEAN' ];
	}
}

1;

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

