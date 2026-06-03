=head1 NAME

EPrints::Plugin::Convert::SRTtoVTT

=cut

package EPrints::Plugin::Convert::SRTtoVTT;

use strict;

our @ISA = qw( EPrints::Plugin::Convert );

sub new
{
	my( $class, %opts ) = @_;

	my $self = $class->SUPER::new( %opts );

	$self->{name} = "SRT to VTT";
	$self->{visible} = "all";
	$self->{advertise} = 1;

	return $self;
}

sub can_convert
{
        my ($plugin, $doc) = @_;

        # Get the main file name
        my $fn = $doc->get_main() or return ();

        my $mimetype = 'text/vtt';

        my @type = ($mimetype => {
                plugin => $plugin,
                encoding => 'utf-8',
                phraseid => $plugin->html_phrase_id( $mimetype ),
        });

        if( $fn =~ /\.srt$/i )
        {
                return @type;
        }

        return ();
}


sub export
{
	my( $self, $dir, $doc, $type ) = @_;

	my @results;
	foreach my $file ( @{($doc->get_value( "files" ))} )
	{
		my $filename_in = $file->get_value( "filename" );
		next unless $filename_in =~ m/\.srt$/i;
		my $filename_out = $` . ".vtt";

		open( FH_OUT, ">:utf8", "$dir/$filename_out" );
		open( FH_IN, "<:utf8", $file->get_local_copy );
		print FH_OUT "WEBVTT\n\n";
		while( <FH_IN> )
		{
			s/^(\d\d:\d\d:\d\d),(\d\d\d) --> (\d\d:\d\d:\d\d),(\d\d\d)/$1.$2 --> $3.$4/; # replace commas for dots in timestamps
			print FH_OUT $_;
		}
		close( FH_OUT );
		push @results, $filename_out;
	}

	return @results;
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
