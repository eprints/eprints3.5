######################################################################
#
# EPrints::MetaField::Search
#
######################################################################
#
#
######################################################################

=pod

=for Pod2Wiki

=head1 NAME

B<EPrints::MetaField::Search> - no description

=head1 DESCRIPTION

not done

=over 4

=cut

# datasetid

package EPrints::MetaField::Search;

use strict;
use warnings;

BEGIN
{
	our( @ISA );

	@ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;


sub render_single_value
{
	my( $self, $session, $value ) = @_;

	my $searchexp = $self->make_searchexp( $session, $value );

	return $session->make_text( $value ) if !defined $searchexp;

	return $searchexp->render_description;
}


######################################################################
# 
# $searchexp = $field->make_searchexp( $session, $value, [$basename] )
#
# This method should only be called on fields of type "search". 
# Return a search expression from the serialised expression in value.
# $basename is passed to the Search to prefix all HTML form
# field ids when more than one search will exist in the same form. 
#
######################################################################

sub make_searchexp
{
	my( $self, $session, $value, $basename, $obj ) = @_;

	my $dataset = $session->dataset( $self->{datasetid} );

	my $searchexp = EPrints::Search->new(
		session => $session,
		dataset => $dataset,
		prefix => $basename );

	# new-style search spec
	if( defined $value && $value =~ /^\?/ )
	{
		my $url = URI->new( $value );
		my %spec = $url->query_form;
		$searchexp = $session->plugin( "Search::$spec{plugin}",
			dataset => $dataset,
			prefix => $basename,
		);
		if( !defined $searchexp )
		{
			$session->log( "Unknown search plugin in: $value" );
			return;
		}
		$value = $spec{exp};
	}

	my $fields;
	my $conf_key = $self->get_property( "fieldnames_config" );
	if( defined($conf_key) )
	{
		$fields = $session->config( $conf_key );
		#if we've been passed a function, get the array from that
		if( ref( $fields ) eq "CODE" )
		{			
			$fields = $self->call_property( "fieldnames_config", 
				$self,
				$session,	
				$value,
				$dataset,
				$obj );
		}

	}
	else
	{
		$fields = $self->get_property( "fieldnames" );
	}

	$fields = [] if !defined $fields;

	foreach my $fieldname (@$fields)
	{
		if( !$dataset->has_field( $fieldname ) )
		{
			$session->get_repository->log( "Field specified in search field configuration $conf_key does not exist in dataset ".$dataset->confid.": $fieldname" );
			next;
		}
		$searchexp->add_field(
			fields => [$dataset->get_field( $fieldname )],
		);
	}

	if( defined $value )
	{
		if( scalar @$fields )
		{
			$searchexp->from_string( $value );
		}
		else
		{
			$searchexp->from_string_raw( $value );
		}
	}

	return $searchexp;
}		

sub get_basic_input_elements
{
	my( $self, $session, $value, $basename, $staff, $obj ) = @_;

	#cjg NOT CSS'd properly.

	my $div = $session->make_element( 
		"div", 
		style => "padding: 6pt; margin-left: 24pt; " );

	# cjg - make help an option?

	my $searchexp = $self->make_searchexp( $session, $value, $basename."_", $obj );

	foreach my $sf ( $searchexp->get_non_filter_searchfields )
	{		
		my $ft = $sf->{"field"}->get_type();
		my $div_id;
		my $field;
		if ( ( $ft eq "set" || $ft eq "namedset" ) && $sf->{"field"}->{search_input_style} eq "checkbox" )
		{
			$div_id = $basename."_".$sf->{id}."_legend_label";
			$field = $sf->render( legend => EPrints::Utils::tree_to_utf8( $sf->render_name ) . " " . EPrints::Utils::tree_to_utf8( $session->html_phrase( "lib/searchfield:desc:set_legend_suffix" ) ) );
		}
		else
		{
			$div_id = $basename."_".$sf->{id}."_label";
			$field = $sf->render();	
		}

		my $sfdiv = $session->make_element( 
				"div" , 
				class => "ep_search_field_name",
				id => $div_id );
		$sfdiv->appendChild( $sf->render_name );
		$div->appendChild( $sfdiv );
		$div->appendChild( $field );
	}

	return [ [ { el=>$div } ] ];
}


sub form_value_basic
{
	my( $self, $session, $basename ) = @_;
	
	my $searchexp = $self->make_searchexp( $session, undef, $basename."_" );

	foreach my $sf ( $searchexp->get_non_filter_searchfields )
	{
		$sf->from_form();
	}

	foreach my $sf ( $searchexp->get_non_filter_searchfields )
	{
		$sf->from_form;
	}
	my $value = undef;
	unless( $searchexp->is_blank )
	{
		$value = $searchexp->serialise;	
	}

	# replace UTF8-MB4 characters with a �
	$value=~s/[^\N{U+0000}-\N{U+FFFF}]/\N{REPLACEMENT CHARACTER}/g if defined $value && $session->config( 'dbcharset' ) ne "utf8mb4";

	return $value;
}

sub get_search_group { return 'search'; } 

sub get_property_defaults
{
	my( $self ) = @_;
	my %defaults = $self->SUPER::get_property_defaults;
	$defaults{datasetid} = $EPrints::MetaField::REQUIRED;
	$defaults{fieldnames} = $EPrints::MetaField::UNDEF;
	$defaults{fieldnames_config} = $EPrints::MetaField::UNDEF;
	return %defaults;
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

