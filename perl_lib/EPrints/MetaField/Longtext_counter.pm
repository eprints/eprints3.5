######################################################################
#
# EPrints::MetaField::Longtext_counter;
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

B<EPrints::MetaField::Longtext_counter> Longtext input field with character counter.

=head1 DESCRIPTION
Renders the input field with additional character counter.

=over 4

=cut

package EPrints::MetaField::Longtext_counter;

use strict;
use warnings;

BEGIN
{
        our( @ISA );

        @ISA = qw( EPrints::MetaField::Longtext );
}

use EPrints::MetaField::Longtext;



sub get_basic_input_elements
{
        my( $self, $session, $value, $basename, $staff, $obj, $one_field_component ) = @_;

        my %defaults = $self->get_property_defaults;

        my @classes = defined $self->{dataset} ?
                join('_', 'ep', $self->dataset->base_id, $self->name) :
                ();

	my %attributes = (
                name => $basename,
                id => $basename,
                class => join(' ', @classes),
                rows => $self->{input_rows},
                cols => $self->{input_cols},
                maxlength => $self->{maxlength},
                wrap => "virtual",
		'aria-labelledby' => $self->get_labelledby( $basename ),
	);
	my $describedby = $self->get_describedby( $basename, $one_field_component );
	$attributes{'aria-describedby'} = $describedby if EPrints::Utils::is_set( $describedby );
	my $textarea = $session->make_element( "textarea", %attributes );
	$textarea->appendChild( $session->make_text( $value ) );

	my $frag = $session->make_doc_fragment;
	$frag->appendChild($textarea);

	my $final_max_words = 0;

	if ( defined $self->{maxwords} && $self->{maxwords} )
	{
		$final_max_words = $self->{maxwords};
	}
	elsif ( !defined $self->{maxwords} && $defaults{maxwords} )
	{
		$final_max_words = $defaults{maxwords};
	}

	my @words = split( /\s+/, $value );
	my $p;
	if ( $final_max_words && scalar @words > $final_max_words )
	{
		$p = $session->make_element( "p", id=>$basename . "_counter_line", class => "ep_over_word_limit");
	}
	else
	{
		$p = $session->make_element( "p", id=>$basename . "_counter_line" );
	}
	$p->appendChild($session->make_element( "span", id=>$basename."_display_count"));
	$p->appendChild( $session->make_text( "/".$final_max_words ) ) if $final_max_words;
	$p->appendChild( $session->html_phrase( "lib/metafield:words" ) );

	$frag->appendChild( $p );

	$frag->appendChild( $session->make_javascript( <<EOJ ) );
function getWordCount(words_string)
{
	var words = words_string.split(/\\W+/);
	var word_count = words.length;
	if (word_count > 0 && words[word_count-1] == "")
	{
		word_count--;
	}
	return word_count;
}

{
	const element = document.getElementById('$basename');
	const counterDisplay = document.getElementById('${basename}_display_count');
	const counterLine = document.getElementById('${basename}_counter_line');

	element.addEventListener('input', () => {
		const totalWords = getWordCount(element.value);
		counterDisplay.innerText = totalWords;
		if (max_words > 0 && totalWords > $final_max_words) {
			counterLine.setAttribute('class', 'ep_over_word_limit');
		} else if (counterLine.getAttribute('class') === 'ep_over_word_limit') {
			counterLine.removeAttribute('class');
		}
	});

	const totalWords = getWordCount(element.value);
	counterDisplay.innerText = totalWords;
	if ((max_words > 0 && totalWords > $final_max_words) {
		counterLine.setAttribute('class', 'ep_over_word_limit');
	}
}
EOJ

        return [ [ { el=>$frag } ] ];
}

sub get_property_defaults
{
        my( $self ) = @_;
        my %defaults = $self->SUPER::get_property_defaults;
		$defaults{maxwords} = $EPrints::MetaField::FALSE;
        return %defaults;
}





######################################################################
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
