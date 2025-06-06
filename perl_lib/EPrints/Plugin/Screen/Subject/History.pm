=head1 NAME

=encoding utf8

EPrints::Plugin::Screen::Subject::History

=cut

package EPrints::Plugin::Screen::Subject::History;

our @ISA = ( 'EPrints::Plugin::Screen' );

use Digest::MD5 qw( md5 );
use JSON;
use List::Util qw( max min );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	$self->{expensive} = 1;
	$self->{appears} = [
		{
			place => 'subject_edit_tabs',
			position => 500,
		}
	];

	return $self;
}

sub can_be_viewed
{
	return 1;
}

sub render
{
	my( $self ) = @_;
	my $repo = $self->{repository};
	my $processor = $self->{processor};

	my $subject_id = $processor->{dataobj}->id;
	my $list = $repo->dataset( 'history' )->search(
		filters => [
			{ meta_fields => [qw( datasetid )], value => 'subject' },
			{ meta_fields => [qw( objectid )], value => unpack( 'l', md5( $subject_id ) ) },
		],
		custom_order => '-historyid',
	);

	return EPrints::Paginate->paginate_list(
		$repo,
		undef,
		$list,
		params => { $processor->{screen}->hidden_bits },
		container => $repo->make_element( 'div' ),
		render_result => sub {
			my( undef, $item ) = @_;

			return $self->render_history( $item, $subject_id );
		},
	);
}

sub render_history
{
	my( $self, $item, $objectid ) = @_;
	my $repo = $self->{repository};

	my %pins = ();
	my $user = $item->get_user;

	my $datasetid = $item->get_value( 'datasetid' );
	$item->set_value( 'objectid', $objectid );
	if( defined $item->get_dataobj ) {
		$pins{item} = $repo->make_doc_fragment;
		$pins{item}->appendChild( $item->get_dataobj->render_description );
		my $revision = $item->get_value( 'revision' );
		$pins{item}->appendChild( $repo->make_text( " ($datasetid $objectid r$revision)" ) );
	} else {
		$pins{item} = $repo->html_phrase(
			'lib/history:no_such_item',
			datasetid => $repo->make_text( $datasetid ),
			objectid => $repo->make_text( $objectid ),
		);
	}

	if( defined $user ) {
		$pins{cause} = $user->render_description;
	} else {
		$pins{cause} = $repo->make_element( 'tt' );
		$pins{cause}->appendChild( $repo->make_text( $item->get_value( 'actor' ) ) );
	}

	$pins{when} = $item->render_value( 'timestamp' );
	$pins{action} = $item->render_value( 'action' );

	$pins{details} = $repo->make_element( 'table', class => 'ep_history_diff_table' );
	my $tr = $pins{details}->appendChild( $repo->make_element( 'tr' ) );
	my $td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 10%;' ) );
	$td->appendChild( $repo->html_phrase( 'Plugin/Screen/Subject/History:field' ) );
	$td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 45%;' ) );
	$td->appendChild( $repo->html_phrase( 'lib/history:before' ) );
	$td = $tr->appendChild( $repo->make_element( 'th', style => 'width: 45%;' ) );
	$td->appendChild( $repo->html_phrase( 'lib/history:after' ) );

	my $values = from_json( $item->get_value( 'details' ) );
	for my $field (@{$repo->config( 'subject_history_fields' )}) {
		next if !defined $values->{$field};
		my( $old_value, $new_value ) = @{$values->{$field}};

		my $tr = $pins{details}->appendChild( $repo->make_element( 'tr' ) );
		my $th = $tr->appendChild( $repo->make_element( 'th', style => 'width: 10%;' ) );
		$th->appendChild( $repo->html_phrase( "subject_fieldname_$field" ) );
		my( $left, $right ) = $self->render_history_diff( $old_value, $new_value );
		$tr->appendChild( $left );
		$tr->appendChild( $right );
	}

	return $repo->html_phrase( 'lib/history:record', %pins );
}

######################################################################
=pod

=over 4

=item $text = $screen->render_history_diff( $left, $right )

Returns two <td> elements (left and right) to show the difference between the
passed in C<$left> and C<$right> items.

This currently supports:

=over 4

=item * Numbers  - Displayed as -3.14

=item * Strings  - Displayed as "Hello"

=item * C<undef> - Displayed as UNSPECIFIED

=item * Lists of Numbers, Strings and C<undef> - Displayed as [<contents>]

=back

However as an exception a list can only be opposite another list (or C<undef>
on the left).

=cut
######################################################################

sub render_history_diff
{
	my( $self, $left, $right ) = @_;
	my $repo = $self->{repository};
	my $width = ($repo->config( 'max_history_width' ) || 120) / 2;

	sub render_scalar {
		my( $repo, $value ) = @_;
		if( $value =~ /^-?\d*(?:\.?\d+)$/ ) { # Display anything that looks like a number 'as-is'
			return $value;
		} elsif( defined $value ) { # Display any defined non-numbers as strings
			return "\"$value\"";
		} else { # Display undef as 'UNSPECIFIED'
			return $repo->phrase( 'lib/metafield:unspecified' );
		}
	}

	sub render_list_portion {
		my( $repo, @list ) = @_;
		my $text = '';
		for my $item (@list) {
			$text .= "\n  " . render_scalar( $repo, $item ) . ',';
		}
		return $text;
	}

	my $td_left = $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' );
	my $td_right = $repo->make_element( 'td', class => 'ep_history_diff_table_change', style => 'width: 45%;' );
	my $pre_left = $td_left->appendChild( $repo->make_element( 'pre', class => 'ep_history_xmlblock' ) );
	my $pre_right = $td_right->appendChild( $repo->make_element( 'pre', class => 'ep_history_xmlblock' ) );

	# If the left is undefined then this field has been set for the first time
	if( !defined $left ) {
		if( ref( $right ) eq 'ARRAY' ) {
			my( $created, $line_count ) = wrap_text( '[' . render_list_portion( $repo, @{$right} ) . "\n]", $width );
			my $left_span = $pre_left->appendChild( $repo->make_element( 'span' ) );
			$left_span->appendChild( $repo->make_text( "\n" x $line_count ) );
			$pre_right->appendChild( $repo->make_text( $created ) );
		} else {
			$pre_left->appendChild( $repo->render_nbsp );
			$pre_right->appendChild( $repo->make_text( render_scalar( $repo, $right ) ) );
		}

		delete $td_left->{class};
		$td_right->{class} = 'ep_history_diff_table_add';

		return( $td_left, $td_right );
	} elsif( ref( $right ) ne 'ARRAY' ) {
		my $left_span = $pre_left->appendChild( $repo->make_element( 'span', style => 'background: #cc0;' ) );
		my $right_span = $pre_right->appendChild( $repo->make_element( 'span', style => 'background: #cc0;' ) );

		$left_span->appendChild( $repo->make_text( render_scalar( $repo, $left ) ) );
		$right_span->appendChild( $repo->make_text( render_scalar( $repo, $right ) ) );

		return( $td_left, $td_right );
	}

	# If we didn't return then it is a list on both sides, so open the list
	$pre_left->appendChild( $repo->make_text( '[' ) );
	$pre_right->appendChild( $repo->make_text( '[' ) );

	my @diff = myers_diff( $left, $right );
	# Add a fake operation so that it will add the text between the last operation and the end
	push @diff, { operation => 'end', left_idx => scalar @{$left}, right_idx => scalar @{$right} };

	my $left_idx = 0;
	my $right_idx = 0;
	for my $diff_op (@diff) {
		# Add text up to the next operation to both sides
		my $text = wrap_text(
			render_list_portion( $repo, @{$left}[ $left_idx .. $diff_op->{left_idx} - 1 ] ),
			$width
		);
		$pre_left->appendChild( $repo->make_text( $text ) );
		$pre_right->appendChild( $repo->make_text( $text ) );
		$left_idx = $diff_op->{left_idx};
		$right_idx = $diff_op->{right_idx};

		my @change = $diff_op->{change_start} .. $diff_op->{change_end};
		if( $diff_op->{operation} eq 'insert' ) {
			my( $inserted, $newlines ) = wrap_text(
				render_list_portion( $repo, @{$right}[ @change ] ),
				$width
			);
			$pre_left->appendChild( $repo->make_text( "\n" x ($newlines - 1) ) );

			my $right_span = $pre_right->appendChild( $repo->make_element( 'span', style => 'background: #8f8;' ) );
			$right_span->appendChild( $repo->make_text( $inserted ) );
			$right_idx = $diff_op->{change_end} + 1;
		} elsif( $diff_op->{operation} eq 'delete' ) {
			my( $deleted, $newlines ) = wrap_text(
				render_list_portion( $repo, @{$left}[ @change ] ),
				$width
			);
			$pre_right->appendChild( $repo->make_text( "\n" x ($newlines - 1) ) );

			my $left_span = $pre_left->appendChild( $repo->make_element( 'span', style => 'background: #f88;' ) );
			$left_span->appendChild( $repo->make_text( $deleted ) );
			$left_idx = $diff_op->{change_end} + 1;
		}
	}

	$pre_left->appendChild( $repo->make_text( "\n]" ) );
	$pre_right->appendChild( $repo->make_text( "\n]" ) );

	return( $td_left, $td_right );
}

######################################################################
=pod

=item $text = Self::wrap_text( $text: str, $width: int )

=item ($text, $lines) = Self::wrap_text( $text: str, $width: int )

This wraps the given C<text> to a maximum width of C<width>, adding (↲) to
denote line breaks. If called in ARRAY context it will also return the
line count of the new text.

=cut
######################################################################

sub wrap_text
{
	my( $text, $width ) = @_;

	my $line_break = chr(8626); # The character to use as a line break (↲)
	my @lines = ();
	foreach my $line ( split /[\r\n]/, $text ) {
		while( length( $line ) > $width ) {
			my $cut = $width - 1;
			push @lines, substr( $line, 0, $cut ) . $line_break;
			$line = substr( $line, $cut );
		}
		push @lines, $line;
	}

	# Return the line count as well if an array is requested
	if( wantarray ) {
		return( join( "\n", @lines ), scalar @lines );
	} else {
		return join( "\n", @lines );
	}
}

######################################################################
=pod

=item @changes = Self::myers_diff( $left: &[str], $right: &[str] )

This applies the Eugene Myers Diff Algorithm to the C<left> and C<right>
array refs of strings, returning an array of changes.

These changes are of the form:

 {
   operation => 'insert' | 'delete',
   change_start => <int>, # Where the change starts on the relevant side
   change_end => <int>,   # Where the change ends, so the change is @<left|right>[$change_start .. $change_end]
   left_idx => <int>,  # The left index, equal to 'change_start' for 'delete'
   right_idx => <int>, # The right index, equal to 'change_start' for 'insert'
 }

=cut
######################################################################

sub myers_diff
{
	my( $left_ref, $right_ref, $left_idx, $right_idx ) = @_;
	my @left = @{$left_ref};
	my @right = @{$right_ref};
	$left_idx = 0 unless $left_idx;
	$right_idx = 0 unless $right_idx;

	my $joint_len = @left + @right;
	my $array_len = 2 * min( scalar @left, scalar @right ) + 2;
	if( @left > 0 && @right > 0 ) {
		my @g = (0) x $array_len;
		my @p = (0) x $array_len;
		for my $h (0 .. (int($joint_len / 2) + $joint_len % 2)) {
			for my $r (0 .. 1) {
				my $m = $r ? -1 : 1;

				for( my $k = -($h - 2 * max(0, $h - @right)); $k <= $h - 2 * max(0, $h - @left); $k += 2 ) {
					my $left_offset;
					if( $k == -$h || ($k != $h && $g[($k - 1) % $array_len] < $g[($k + 1) % $array_len]) ) {
						$left_offset = $g[($k + 1) % $array_len];
					} else {
						$left_offset = $g[($k - 1) % $array_len] + 1;
					}
					my $right_offset = $left_offset - $k;
					my $s = $left_offset;
					my $t = $right_offset;
					while(
						$left_offset < @left &&
						$right_offset < @right &&
						$left[$r * (@left - 1) + $m * $left_offset] eq $right[$r * (@right - 1) + $m * $right_offset]
					) {
						$left_offset++;
						$right_offset++;
					}
					$g[$k % $array_len] = $left_offset;
					my $z = -$k + @left - @right;
					if(
						$joint_len % 2 == 1 - $r &&
						$z >= (1 - $h - $r) &&
						$z <= ($h + $r - 1) &&
						$g[$k % $array_len] + $p[$z % $array_len] >= scalar @left
					) {
						my $x = $r ? @left - $left_offset : $s;
						my $y = $r ? @right - $right_offset : $t;
						my $u = $r ? @left - $s : $left_offset;
						my $v = $r ? @right - $t : $right_offset;
						if( 2 * $h + $r > 2 || ( $x != $u && $y != $v ) ) {
							my @left_diff = myers_diff( [@left[0 .. $x - 1]], [@right[0 .. $y - 1]], $left_idx, $right_idx );
							my @right_diff = myers_diff( [@left[$u .. @left - 1]], [@right[$v .. @right - 1]], $left_idx + $u, $right_idx + $v );

							# Combine matching operations
							if( scalar @left_diff && scalar @right_diff && $left_diff[-1]->{operation} eq $right_diff[0]->{operation} ) {
								# Only combine operations if the end of one matches the start of the next
								if( $left_diff[-1]->{change_end} + 1 == $right_diff[0]->{change_start} ) {
									$left_diff[-1]->{change_end} = $right_diff[0]->{change_end};
									@right_diff = @right_diff[1 .. @right_diff - 1];
								}
							}

							return( @left_diff, @right_diff );
						} elsif ( @right > @left ) {
							return myers_diff( [], [@right[scalar @left .. scalar @right - 1]], $left_idx + @left, $right_idx + @left );
						} elsif ( @right < @left ) {
							return myers_diff( [@left[scalar @right .. scalar @left - 1]], [], $left_idx + @right, $right_idx + @right );
						} else {
							return ();
						}
					}
				}

				my @temp = @g;
				@g = @p;
				@p = @temp;
			}
		}
	} elsif( scalar @left > 0) {
		return( { operation => 'delete', change_start => $left_idx, change_end => $left_idx + @left - 1, left_idx => $left_idx, right_idx => $right_idx } );
	} elsif( scalar @right > 0) {
		return( { operation => 'insert', change_start => $right_idx, change_end => $right_idx + @right - 1, left_idx => $left_idx, right_idx => $right_idx } );
	} else {
		return ();
	}
}

1;

=back

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

