# invocation strings for available executables
$c->{invocation} ||= {};
{
my %invocations = (
	 'convert_crop_white' => '$(convert) -crop 0x0 -bordercolor white -border 4x4 $(SOURCE) $(TARGET)',
	 'dvips' => '$(dvips) $(SOURCE) -o $(TARGET)',
	 'sendmail' => '$(sendmail) -oi -t -odb --',
	 'html2text' => '$(html2text) --images-to-alt --unicode-snob $(SOURCE) > $(TARGET)',
	 'latex' => '$(latex) -no-shell-escape -output-directory=$(TARGET) $(SOURCE)',
	 'targz' => '$(gunzip) -c < $(ARC) 2>/dev/null | $(tar) xf - -C $(DIR) >/dev/null 2>&1',
	 'antiwordpdf' => '$(antiword) -a a4 -m 8859-1 $(SOURCE) > $(TARGET)',
	 'pdftotext' => '$(pdftotext) -q -enc UTF-8 -layout $(SOURCE) $(TARGET)',
	 'zip' => '$(unzip) 1>/dev/null 2>&1 -qq -o -d $(DIR) $(ARC)',
	 'unzip' => '$(unzip) 1>/dev/null 2>&1 -qq -o -j -d $(DIRECTORY) $(SOURCE)',
	 'cpall' => '$(cp) -pR $(SOURCE)/* $(TARGET)',
	 'wget' => '$(wget) -U "Mozilla/5.0" -p -q -nH --execute="robots=off" --cut-dirs=$(CUTDIRS) --content-disposition $(URL)',
	 'antiword' => '$(antiword) -t -f -m UTF-8 $(SOURCE) > $(TARGET)',
	 'doc2txt' => '$(perl) $(doc2txt) $(SOURCE) $(TARGET)',
	 'rtf2txt' => '$(perl) $(rtf2txt) $(SOURCE) $(TARGET)',
	 'rmall' => '$(rm) -rf $(TARGET)/*',
	 'ffmpeg_i' => '$(ffmpeg) -i $(SOURCE)',

	#'ffmpeg_video_mp4' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) -vcodec $(video_codec) -r $(video_frame_rate) -b:v $(video_bitrate) -s $(width)x$(height) $(TARGET)',
	 'ffmpeg_video_mp4' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -strict -2 -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) -vcodec $(video_codec) -r $(video_frame_rate) -b:v $(video_bitrate) -s $(width)x$(height) $(TARGET)',
	 'ffmpeg_video_ogg' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) -vcodec $(video_codec) -r $(video_frame_rate) -b:v $(video_bitrate) -s $(width)x$(height) $(TARGET)',
	 'ffmpeg_video_webm'=> '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) -vcodec $(video_codec) -r $(video_frame_rate) -b:v $(video_bitrate) -s $(width)x$(height) $(TARGET)',

	#'ffmpeg_audio_mp4' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) $(TARGET)',
	 'ffmpeg_audio_mp4' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -strict -2 -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) $(TARGET)',
	 'ffmpeg_audio_ogg' => '$(ffmpeg) -y -i $(SOURCE) -threads $(ffmpeg_threads) -acodec $(audio_codec) -ac 2 -ar $(audio_sampling) -ab $(audio_bitrate) -f $(container) $(TARGET)',

	 'ffmpeg_cell' => '$(ffmpeg) -y -i $(SOURCE) -an -f mjpeg -ss $(offset) -t 00:00:01 -r 1 -s $(width)x$(height) $(TARGET)',
	 'unoconv' => '$(unoconv) -f $(FORMAT) $(SOURCE)',
	 'txt2refs' => '$(perl) $(txt2refs) $(SOURCE) $(TARGET)',
	 'ffprobe' => '$(ffprobe) -show_streams $(SOURCE)',
	 'cal' => '$(cal) $(MONTH) $(YEAR)',
	 'ncal' => '$(ncal) -b -h $(MONTH) $(YEAR)',
);
while(my( $name, $invo ) = each %invocations)
{
	next if exists $c->{invocation}->{$name};
	$c->{invocation}->{$name} = $invo;
}
}

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
