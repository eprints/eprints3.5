######################################################################
#
# EPrints::ScreenProcessor
#
######################################################################
#
#
######################################################################

=pod

=head1 NAME

EPrints::ScreenProcessor

=cut

package EPrints::ScreenProcessor;

use strict;

=item $processor = EPrints::ScreenProcessor->new( %opts )

=cut

sub new
{
	my( $class, %self ) = @_;

	$self{messages} = [];
	$self{after_messages} = [];
	$self{before_messages} = [];

	$self{session} = ($self{repository} ||= $self{session});
	if( !defined $self{session} ) 
	{
		EPrints::abort( "session not passed to EPrints::ScreenProcessor->process" );
	}

	my $self = bless \%self, $class;

	$self->cache_list_items();

	if( !defined $self{screenid} )
	{
		$self{screenid} = "FirstTool";
	}

	my $user = $self{session}->current_user;
	if( defined $user )
	{
		$self{user} = $user;
		$self{userid} = $user->id;
	}

	return $self;
}

=item $processor->cache_list_items()

Caches all of the screen plugin appearances/actions.

=cut

sub cache_list_items
{
	my( $self ) = @_;

	my $session = $self->{session};

	my $screen_lists = $session->get_plugin_factory->cache( "screen_lists" );

	return $screen_lists if defined $screen_lists;

	$screen_lists = {};

	my $p_conf = $session->config( "plugins" );

	my @screens = $session->get_plugins( {
			processor => $self,
		},
		type => "Screen" );

	foreach my $screen (@screens)
	{
		my $screen_id = $screen->get_id;
		my %app_conf = %{($p_conf->{$screen_id} || {})->{appears} || {}};
		my %acc_conf = %{($p_conf->{$screen_id} || {})->{actions} || {}};
		my %appears;
		my %actions;
		foreach my $opt (@{$screen->{appears} || []})
		{
			my $place = $opt->{place};
			my $position = $opt->{position};
			my $action = $opt->{action};

			if( !defined $place )
			{
				$session->log( "Warning! ".ref($screen)." wants to appear somewhere but doesn't specify the place to appear" );
				next;
			}

			$position = 999999 if !defined $position;
			
			if( defined $action )
			{
				next if $acc_conf{$action}->{disable};
				$actions{$place}->{$action} = $position;
			}
			else
			{
				$appears{$place} = $position;
			}
		}
		foreach my $action (keys %acc_conf)
		{
			next if $acc_conf{$action}->{disable};
			while(my( $place, $pos ) = each %{$acc_conf{$action}->{appears}})
			{
				$actions{$place}->{$action} = $pos;
			}
		}
		foreach my $place (keys %app_conf)
		{
			if( defined $app_conf{$place} )
			{
				$appears{$place} = $app_conf{$place};
			}
			else
			{
				delete $appears{$place};
				delete $actions{$place};
			}
		}
		foreach my $place (keys %appears)
		{
			push @{$screen_lists->{$place}}, {
				screen_id => $screen_id,
				position => $appears{$place},
			};
		}
		foreach my $place (keys %actions)
		{
			foreach my $action (keys %{$actions{$place}})
			{
				push @{$screen_lists->{$place}}, {
					screen_id => $screen_id,
					position => $actions{$place}->{$action},
					action => $action,
				};
			}
		}
	}

	foreach my $item_list (values %$screen_lists)
	{
                my @item_list_tmp = ();
                foreach my $item (@$item_list)
                {
                        push @item_list_tmp, $item if defined $item && defined $item->{position};
                }
                $item_list = \@item_list_tmp;
                @$item_list = sort { $a->{position} <=> $b->{position} } @$item_list;
	}

	return $session->get_plugin_factory->cache( "screen_lists", $screen_lists );
}

=item @screen_opts = $processor->list_items( $list_id, %opts )

Returns a list of screens that appear in list $list_id ordered by their position.

If $list_id is an array ref returns all matching entries for each individual list.

Each screen opt is a hash ref of:

	screen - screen plugin
	screen_id - screen id
	position - position (positive integer)
	action - the action, if this plugin is for an action list

Incoming opts:

	filter => 1 or 0 (default 1)

=cut

sub list_items
{
	my( $self, $list_id, %opts ) = @_;

	my $filter = $opts{filter};
	$filter = 1 if !defined $filter;

	my $screen_lists = $self->{session}->get_plugin_factory->cache( "screen_lists" );

	my @opts;
	for(ref($list_id) eq "ARRAY" ? @$list_id : $list_id)
	{
		push @opts, @{$screen_lists->{$_} || []};
	}

	my @list;
	foreach my $opt (@opts)
	{
		my $screen = $self->{session}->plugin( $opt->{screen_id}, processor=>$self, %{$opts{params}||{}} );
		if( $filter )
		{
			next if !$screen->can_be_viewed;
			if( defined $opt->{action} )
			{
				next if !$screen->allow_action( $opt->{action} );
			}
		}
		if ( defined $screen->{class} )
                {
                        $opt->{class} = $screen->{class} unless defined $opt->{class};
                        $opt->{class} .= " " . $screen->{class} if defined $opt->{class};
                }
		push @list, {
			%$opt,
			screen => $screen,
		};
	}

	return @list;
}

=item $frag = $processor->render_item_list( $items, %opts )

Renders a list of items as returned by L</list_items>.

Options:

	class - set the class used on the <ul>

=cut

sub render_item_list
{
	my( $self, $list, %opts ) = @_;

	my $item = {
		class => $opts{class},
		entries => [],
	};


	foreach my $entry ( @$list )
	{
		my $screen = $entry->{screen};
		my $item_list_class = "";

		$item_list_class = $self->{session}->config( 'item_list_class' ) if defined $self->{session}->config( 'item_list_class' );
		$item_list_class .= $screen->{class} if defined $screen->{class};		

		push @{ $item->{entries} }, {
			id => $entry->{screen}->{id},
			class => $item_list_class,
			item => $entry->{screen}->render_action_link,
			title => $entry->{screen}->render_title,
		};
	}

	return $self->{session}->template_phrase( "view:EPrints/ScreenProcessor:render_item_list", { item => $item } );
}

=item $frag = $processor->render_toolbar( %opts )

Renders and returns a toolbar of any screens in the B<key_tools> or B<other_tools> action sets.

=cut

sub render_toolbar
{
	my( $self ) = @_;

	my $class = $self->{session}->config( "toolbar_class" ) if defined $self->{session}->config( "toolbar_class" );

	my $toolbar = $self->render_item_list( [
		$self->list_items( "key_tools" ),
	], ( class => $class ) );

	if ( -e $self->{session}->config( 'variables_path' ) ."/developer_mode_on" && $self->{session}->config( 'developer_mode', 'show_banner' ))
	{
		my $dev_banner = $self->{session}->make_element( 'div', class => 'ep_dev_banner' );
		$dev_banner->appendChild( $self->{session}->html_phrase( "developer_banner_text" ) );
		$toolbar->appendChild( $dev_banner );
	}

	return $toolbar;
}

=item EPrints::ScreenProcessor->process( %opts )

Process and send a response to a Web request.

=cut

sub process
{
	my( $class, %opts ) = @_;

	if( !defined $opts{screenid} ) 
	{
		$opts{screenid} = $opts{session}->param( "screen" );
	}
	if( !defined $opts{screenid} ) 
	{
		$opts{screenid} = "FirstTool";
	}

	my $self = $class->new( %opts );

	my $current_user = $self->{session}->current_user;

	# Check to make sure CSRF token is set and  has not been changed.
	if ( defined $self->{session}->config( "csrf_token_salt" ) && defined $self->{session}->current_user && $ENV{REQUEST_METHOD} eq "POST" )
	{
		my $csrf_detected = 1;
		if ( defined $opts{session}->param( "csrf_token" ) )
		{
			my @csrf_token_bits = split( ':', $opts{session}->param( "csrf_token" ) );
			if ( scalar @csrf_token_bits eq 2 )
			{
				use Digest::MD5;
	        	        my $ctx = Digest::MD5->new;
        	        	my $csrf_token_expected = $ctx->add( $csrf_token_bits[0], $current_user->get_id, $self->{session}->config( "csrf_token_salt" ) )->hexdigest;
				$csrf_detected = $csrf_token_expected ne $csrf_token_bits[1];
			}
		}
		if ( $csrf_detected )
		{
			$self->add_message( "error", $self->{session}->html_phrase( 
        	                "Plugin/Screen:csrf_detected" ) );
                	$self->{screenid} = "Error";
			EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 403 );
		}
	}

	# This loads the properties of what the screen is about,
	# Rather than parameters for the action, if any.
	$self->screen->properties_from;

	$self->{action} = $self->{session}->get_action_button;
	$self->{internal} = $self->{session}->get_internal_button;
	delete $self->{action} if( $self->{action} eq "" );
	delete $self->{internal} if( $self->{internal} eq "" );

	if( !$self->screen->can_be_viewed )
	{
		$self->screen->register_error;
		$self->{screenid} = "Error";
		EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 403 );
	}
	elsif( !$self->screen->obtain_edit_lock )
	{
		$self->add_message( "error", $self->{session}->html_phrase( 
			"Plugin/Screen:item_locked" ) );
		$self->{screenid} = "Error";
		EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 423 );
	}
	else
	{
		$self->screen->from;
	}

	if( defined $self->{redirect} )
	{
		if( defined $current_user )
		{
			foreach my $message ( @{$self->{messages}} )
			{
				$self->{session}->get_database->save_user_message( 
					$current_user->get_id,
					$message->{type},
					$message->{content} );
			}
		}
		$self->{session}->redirect( $self->{redirect} );
		return;
	}

	# used to swap to a different screen if appropriate
	$self->screen->about_to_render;

	if( $ENV{REQUEST_METHOD} eq "POST" && defined $current_user )
	{
		my $url = $self->screen->redirect_to_me_url;
		if( defined $url )
		{
			foreach my $message ( @{$self->{messages}} )
			{
				$self->{session}->get_database->save_user_message( 
					$current_user->get_id,
					$message->{type},
					$message->{content} );
			}
			$self->{session}->redirect( $url );
			return;
		}
	}
		
	
	# rendering

	if( !$self->screen->can_be_viewed )
	{
		$self->add_message( "error", $self->{session}->html_phrase( 
			"Plugin/Screen:screen_not_allowed",
			screen=>$self->{session}->make_text( $self->{screenid} ) ) );
		$self->{screenid} = "Error";
		EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 403 );
	}
	elsif( !$self->screen->obtain_view_lock )
	{
		$self->add_message( "error", $self->{session}->html_phrase( 
			"Plugin/Screen:item_locked" ) );
		$self->{screenid} = "Error";
		EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 423 );
	}

	# XHTML or special format?
	
	if( $self->screen->wishes_to_export )
	{
		$self->{session}->send_http_header( "content_type"=>$self->screen->export_mimetype );
		$self->screen->export;
		return;
	}

	$self->screen->register_furniture;

	my $content = $self->screen->render;
	my $links = $self->screen->render_links;
	my $title = $self->screen->render_title;

	my $page = $self->{session}->make_doc_fragment;

	foreach my $chunk ( @{$self->{before_messages}} )
	{
		$page->appendChild( $chunk );
	}
	$page->appendChild( $self->render_messages );
	foreach my $chunk ( @{$self->{after_messages}} )
	{
		$page->appendChild( $chunk );
	}

	$page->appendChild( $content );
    
	my $template = $self->{template};
	$template = $self->screen->{template} if defined $self->screen->{template};
	$template = $self->{session}->config( 'plugins', 'Screen::' . $self->{screenid}, 'params', 'template' ) if defined $self->{session}->config( 'plugins', 'Screen::' . $self->{screenid}, 'params', 'template' );
	$template = "default" if not defined $template;

	my $page_id = $self->{screenid};
	$page_id =~ s/::/_/g;
	$page_id .= "_" . $opts{session}->param( "dataset" ) if defined $opts{session}->param( "dataset" );
	$page_id .= "_" . $self->{action} if defined $self->{action};
	$self->{session}->prepare_page(  
		{
			title => $title, 
			page => $page,
			head => $links,
			login_status => $self->render_toolbar,
#			toolbar => $toolbar,
		},
		(
			template => $template,
			page_id => $page_id,
		),
 	);
	$self->{session}->send_page();

	return $self; # useful for unit-tests
}



sub before_messages
{
	my( $self, $chunk ) = @_;

	push @{$self->{before_messages}},$chunk;
}

sub after_messages
{
	my( $self, $chunk ) = @_;

	push @{$self->{after_messages}},$chunk;
}

sub add_message
{
	my( $self, $type, $message ) = @_;

	# we'll sanity check now, otherwise it becomes hard to trace later on
	EPrints->abort( "Requires message argument" ) if !defined $message;

	push @{$self->{messages}},{type=>$type,content=>$message};
}


sub screen
{
	my( $self ) = @_;

	my $screen = $self->{screenid};
	my $plugin_id = "Screen::".$screen;
	$self->{screen} = $self->{session}->plugin( $plugin_id, processor=>$self );

	if( !defined $self->{screen} )
	{
		if( $screen ne "Error" )
		{
			$self->add_message( 
				"error", 
				$self->{session}->html_phrase( 
					"Plugin/Screen:unknown_screen",
					screen=>$self->{session}->make_text( $screen ) ) );
			$self->{screenid} = "Error";
			EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, 400 );
			return $self->screen;
		}
	}

	return $self->{screen};
}

sub render_messages
{	
	my( $self ) = @_;

	my $item = {
                dom_messages => [],
        };

	my @old_messages;
	my $cuser = $self->{session}->current_user;
	if( defined $cuser )
	{
		my $db = $self->{session}->get_database;
		@old_messages = $db->get_user_messages( $cuser->get_id, clear => 1 );
	}
	$self->check_messages_for_status( \@old_messages );
	foreach my $message ( @old_messages, @{$self->{messages}} )
	{
		if( !defined $message->{content} )
		{
			# parse error!
			next;
		}
		push @{$item->{dom_messages}}, { message => $self->{session}->render_message(
                                $message->{type},
                                $message->{content})};
	}

	return $self->{session}->template_phrase( "view:EPrints/ScreenProcessor:render_messages", { item => $item } );
}

sub check_messages_for_status
{
	my ( $self, $old_messages ) = @_;
	foreach my $message ( @$old_messages )
	{
		next unless $message->{type} eq "error";
		my $code = 400;
		$code =  403 if $message->{content} =~ / not perform/i;
		$code = 423 if $message->{content} =~ / locked/i;	
		EPrints::Apache::AnApache::send_hidden_status_line( $self->{"session"}->request, $code );
		last;
	}
}

sub action_not_allowed
{
	my( $self, $action ) = @_;

	$self->add_message( "error", $self->{session}->html_phrase( 
		"Plugin/Screen:action_not_allowed",
		action=>$action ) );
}


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

