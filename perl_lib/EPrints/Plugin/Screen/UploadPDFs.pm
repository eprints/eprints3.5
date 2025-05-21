package EPrints::Plugin::Screen::UploadPDFs;

@ISA = ( 'EPrints::Plugin::Screen' );

use EPrints::Plugin::Screen;
use strict;

our $MAX_ERR_LEN = 1024;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new( %params );

	$self->{actions} = [qw/ import_upload /];

	$self->{appears} = [
		{
			place => "item_tools",
			position => 200,
		}
	];

	if( $self->{session} )
	{
		# screen to go to after a single item import
		$self->{post_import_screen} = $self->param( "post_import_screen" );
		$self->{post_import_screen} ||= "EPrint::Edit";

		# screen to go to after a bulk import
		$self->{post_bulk_import_screen} = $self->param( "post_bulk_import_screen" );
		$self->{post_bulk_import_screen} ||= "Items";
	}

	return $self;
}

sub allow_import_upload { shift->can_be_viewed }

sub properties_from
{
	my( $self ) = @_;

	$self->SUPER::properties_from;

	# dataset to import into
	$self->{processor}->{dataset} = $self->{session}->get_repository->get_dataset( "inbox" );

	$self->{processor}->{plugin} = $self->{session}->plugin(
		"Import::PDF",
		session => $self->{session},
		dataset => $self->{processor}->{dataset},
		processor => $self->{processor},
	);
}

sub render
{
	my( $self ) = @_;

	my $repo = $self->{repository};
	my $xml = $repo->xml;
	my $xhtml = $repo->xhtml;

	my $div = $xml->create_element( "div", class => "ep_block" );

	my $help = $xml->create_element( "p", id => "upload_help" );
	$help->appendChild( $self->html_phrase( "help" ) );
	$div->appendChild( $help );

	my $form = $div->appendChild( $self->{processor}->screen->render_form( "import_file" ) );

	my $input_label = $form->appendChild( $repo->make_element( "label", class => "ep_form_field_input", for => "pdf_upload") );
	my $dropbox = $input_label->appendChild( $repo->make_element( "div", id => "pdf_upload_dropbox", class => "ep_dropbox" ) );
	my $dropbox_text = $dropbox->appendChild( $repo->make_element( "p", class => "ep_dropbox_text" ) );
	my $upload_text = $dropbox_text->appendChild( $repo->make_element( "span", style => "color: blue;" ) );
	$upload_text->appendChild( $repo->make_text( "Click to upload" ) );
	$dropbox_text->appendChild( $repo->make_text( " or drag and drop" ) );

	$dropbox->appendChild( $xhtml->input_field(
		file => undef,
		id => "pdf_upload",
		name => "pdf_upload",
		type => "file",
		multiple => "",
		accept => "application/pdf",
	) );

	$form->appendChild( $repo->make_element( 'br' ) ); # Prevent bootstrap putting the button next to the dropbox

	$form->appendChild( $repo->render_action_buttons(
		import_upload => $repo->phrase( "Plugin/Screen/Import:action_import_upload" ),
		_order => [qw( import_upload )],
	) );

	my $preview_div = $form->appendChild( $repo->make_element( "div", id => "pdf_upload_preview" ) );
	my $preview_p = $preview_div->appendChild( $repo->make_element( "p" ) );
	$preview_p->appendChild( $repo->make_text( "No files currently selected for upload" ) );

	$form->appendChild( $repo->make_element( "script", src => "/javascript/pdf_metadata_import.js" ) );

	return $div;
}

sub render_title
{
	my( $self ) = @_;

	return $self->{session}->html_phrase( "Plugin/Screen/UploadPDFs:title" );
}

sub action_import_upload
{
	my( $self ) = @_;

	$self->{processor}->{current} = 1;

	my @tmp_files = $self->{repository}->get_query->upload( "pdf_upload" );
	return if !defined $tmp_files[0];

	for my $tmp_file (@tmp_files) {
		$tmp_file = *$tmp_file; # CGI file handles aren't proper handles
		return if !defined $tmp_file;
		seek($tmp_file, 0, 0);
	}

	my @filenames = $self->{repository}->get_query->multi_param( "pdf_upload" );
	$self->{processor}->{filenames} = \@filenames;;

	my $list = $self->run_import( @tmp_files );
	return if !defined $list;

	$self->{processor}->{results} = $list;

	$self->post_import( $list );
}

sub run_import
{
	my( $self, @tmp_files ) = @_;

	my $session = $self->{session};
	my $dataset = $self->{processor}->{dataset};
	my $user = $self->{processor}->{user};
	my $plugin = $self->{processor}->{plugin};
	my $show_stderr = $session->config(
		"plugins",
		"Screen::Import",
		"params",
		"show_stderr"
	) || 1;

	$self->{processor}->{count} = 0;

	$plugin->set_handler( EPrints::CLIProcessor->new(
		message => sub { $self->{processor}->add_message( @_ ) },
		epdata_to_dataobj => sub {
			return $self->epdata_to_dataobj( @_ );
		},
	) );

	my $err_file;
	if( $show_stderr )
	{
		$err_file = EPrints->system->capture_stderr();
	}

	my @problems;

	my $list;
	my $i = 0;
	for my $tmp_file (@tmp_files) {
		# Don't let an import plugin die() on us
		my $new_list = eval {
			$plugin->input_fh(
				(),
				dataset  => $dataset,
				fh       => $tmp_file,
				user     => $user,
				filename => $self->{processor}->{filenames}->[$i++],
				actions  => $plugin->param( "actions" ),
				multiple => @tmp_files > 1,
			);
		};

		if( defined $list ) {
			$list = $list->union($new_list);
		} else {
			$list = $new_list;
		}
	}

	if( $show_stderr )
	{
		EPrints->system->restore_stderr( $err_file );
	}

	if( $@ )
	{
		if( $show_stderr )
		{
			push @problems, [
				"error",
				$session->phrase( "Plugin/Screen/Import:exception",
					plugin => $plugin->{id},
					error => $@,
				),
			];
		}
		else
		{
			$session->log( $@ );
			push @problems, [
				"error",
				$session->phrase( "Plugin/Screen/Import:exception",
					plugin => $plugin->{id},
					error => "See Apache error log file",
				),
			];
		}
	}
	elsif( !defined $list && !@{$self->{processor}->{messages}} )
	{
		push @problems, [
			"error",
			$session->phrase( "Plugin/Screen/Import:exception",
				plugin => $plugin->{id},
				error => "Plugin returned undef",
			),
		];
	}

	my $count = $self->{processor}->{count};

	if( $show_stderr )
	{
		my $err;
		sysread($err_file, $err, $MAX_ERR_LEN);
		$err =~ s/\n\n+/\n/g;

		if( length($err) )
		{
			push @problems, [
				"warning",
				$session->phrase( "Plugin/Screen/Import:warning",
					plugin => $plugin->{id},
					warning => $err,
				),
			];
		}
	}

	foreach my $problem (@problems)
	{
		my( $type, $message ) = @$problem;
		$message =~ s/^(.{$MAX_ERR_LEN}).*$/$1 .../s;
		$message =~ s/\t/        /g; # help _mktext out a bit
		$message = join "\n", EPrints::DataObj::History::_mktext( $session, $message, 0, 0, 80 );
		my $pre = $session->make_element( "pre" );
		$pre->appendChild( $session->make_text( $message ) );
		$self->{processor}->add_message( $type, $pre );
	}

	my $ok = (scalar(@problems) == 0 and $count > 0);

	if( $ok )
	{
		$self->{processor}->add_message( "message", $session->html_phrase(
			"Plugin/Screen/Import:import_completed",
			count => $session->make_text( $count )
		) );
	}
	else
	{
		$self->{processor}->add_message( "warning", $session->html_phrase(
			"Plugin/Screen/Import:import_failed",
			count => $session->make_text( $count )
		) );
	}

	return $list;
}

# Unmodified from Screen/Import.pm
sub post_import
{
	my( $self, $list ) = @_;

	my $processor = $self->{processor};

	my $n = $list->count;

	if( $n == 1 )
	{
		my( $eprint ) = $list->get_records( 0, 1 );
		# add in eprint/eprintid for backwards compatibility
		$processor->{dataobj} = $processor->{eprint} = $eprint;
		$processor->{dataobj_id} = $processor->{eprintid} = $eprint->get_id;
		$processor->{screenid} = $self->{post_import_screen};
	}
	elsif( $n > 1 )
	{
		$processor->{screenid} = $self->{post_bulk_import_screen};
	}
}

sub epdata_to_dataobj
{
	my( $self, $epdata, %opts ) = @_;

	$self->{processor}->{count}++;

	my $dataset = $opts{dataset};
	if( $dataset->base_id eq "eprint" )
	{
		$epdata->{userid} = $self->{repository}->current_user->id;
		$epdata->{eprint_status} = "inbox";
	}

	return $dataset->create_dataobj( $epdata );
}

1;
