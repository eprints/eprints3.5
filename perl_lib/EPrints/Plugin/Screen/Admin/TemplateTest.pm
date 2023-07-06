package EPrints::Plugin::Screen::Admin::TemplateTest;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;
use EPrints::XML;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
		{ 
			place => "admin_actions_config", 
			position => 1380, 
		},
	];

	$self->{actions} = [qw( edit )];

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/edit/perl" );
}

sub render
{
	my( $self ) = @_;

	my $session = $self->{session};
	my $user = $session->current_user;

	my $title = sub {

		my $h2 = $session->make_element("h2");
		$h2->appendText( @_ );

		return $h2;
	};

	my $parse = sub {
		my $doc = EPrints::XML::parse_string( $session, @_ );
		return EPrints::XML::contents_of( $doc );
	};

	my $parse_frag = sub {

		my( $string ) = @_;

		my $doc = EPrints::XML::parse_string( $session, "<root>$string</root>" );
		my $frag = $session->make_doc_fragment;

		foreach my $child ( $doc->firstChild->getChildNodes )
		{
			$frag->appendChild( $child );
		}

		return $frag;
	};

    my $page = $session->make_doc_fragment;

	# Basic test. This one just tests that the template_phrase function is
	# doing the most basic test correctly.

	$page->appendChild( &$title( "Basic Test" ));
	$page->appendChild( $session->template_phrase( "view:basic_test" ));

	# Keytools test.

	my $keytools_test =
	{
		'entries' =>
		[
			{
				'item' => &$parse_frag( 'Logged in as <span class="ep_name_citation">Alice</span>' ),
				'id' => 'Screen::Login'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=Items">Manage deposits</a>' ),
				'id' => 'Screen::Items'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=DataSets">Manage records</a>' ),
				'id' => 'Screen::DataSets'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=User%3A%3AView">Profile</a>' ),
				'id' => 'Screen::User::View'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=User%3A%3ASavedSearches">Saved searches</a>' ),
				'id' => 'Screen::User::SavedSearches'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=Review">Review</a>' ),
				'id' => 'Screen::Review'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=Admin">Admin</a>' ),
				'id' => 'Screen::Admin'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/users/home?screen=Admin%3A%3ATemplateTest&amp;edit_phrases=yes">Edit page phrases</a>' ),
				'id' => 'Screen::Admin::Phrases'
			},
			{
				'item' => &$parse_frag( '<a href="/cgi/logout">Logout</a>' ),
				'id' => 'Screen::Logout'
			}
		],
		'id' => 'keytools_test',
		'class' => undef
	};

	$page->appendChild( &$title( "Key Tools Test" ));
	$page->appendChild( $session->template_phrase( "view:EPrints/ScreenProcessor:render_item_list", { item => $keytools_test } ) );

	$keytools_test->{class} = "test_class";
	$keytools_test->{id} = "keytools_test2";

	$page->appendChild( &$title( "Key Tools Test (with custom class)" ));
	$page->appendChild( $session->template_phrase( "view:EPrints/ScreenProcessor:render_item_list", { item => $keytools_test } ) );

	# Manage records test.

	my $manage_records =
	{
		'datasets' =>
		[
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=eprint',
				'label' => 'Eprints',
				'id' => 'eprint'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=event_queue',
				'label' => 'Tasks',
				'id' => 'event_queue'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=file',
				'label' => 'Files',
				'id' => 'file'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=import',
				'label' => 'Imports',
				'id' => 'import'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=saved_search',
				'label' => 'Saved Searches',
				'id' => 'saved_search'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=subject',
				'label' => 'Subjects',
				'id' => 'subject'
			},
			{
				'href' => '/cgi/users/home?screen=Listing&dataset=user',
				'label' => 'Users',
				'id' => 'user'
			}
		]
	};

	$page->appendChild( &$title( "Manage Records Screen" ));
	$page->appendChild( $session->template_phrase( "view:EPrints/Plugin/Screen/DataSets:render", { item => $manage_records } ) );

	# Manage Items test.

	my $items_plugin = $session->plugin( "Screen::Items" );

	$items_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Items",
	);

	$items_plugin->{processor}->{dataset} = $session->dataset( "eprint" );

	$page->appendChild( &$title( "Manage Items Screen" ));
	$page->appendChild( $items_plugin->render );

	# Listing test.

	my $listing_plugin = $session->plugin( "Screen::Listing" );

	$listing_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Listing"
	);

	$listing_plugin->{processor}->{dataset} = $session->dataset( "user" );
	$listing_plugin->properties_from;

	$page->appendChild( &$title( "Listing Screen" ));
	$page->appendChild( $listing_plugin->render );

	# Review test.

	my $review_plugin = $session->plugin( "Screen::Review" );

	$review_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Review"
	);

	$review_plugin->{processor}->{dataset} = $session->dataset( "buffer" );
	$review_plugin->properties_from;

	$page->appendChild( &$title( "Review Screen" ));
	$page->appendChild( $review_plugin->render );

	# Workflow view (details) test.

	my $workflow_view_details_plugin = $session->plugin( "Screen::Workflow::View" );

	$workflow_view_details_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Workflow::View"
	);

	$workflow_view_details_plugin->{processor}->{dataset} = $session->dataset( "user" );
	$workflow_view_details_plugin->{processor}->{dataobj} = $session->dataset( "user" )->dataobj(1);

	$page->appendChild( &$title( "Workflow View Screen - Details" ));
	$page->appendChild( $workflow_view_details_plugin->render() );

	# Workflow view (user history) test.

	my $workflow_view_user_history_plugin = $session->plugin( "Screen::Workflow::View" );

	$workflow_view_user_history_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Workflow::View"
	);

	$workflow_view_user_history_plugin->{processor}->{dataset} = $session->dataset( "user" );
	$workflow_view_user_history_plugin->{processor}->{dataobj} = $session->dataset( "user" )->dataobj(1);

	$session->{query}->{param}->{ep_workflow_views_current} = ["1"];

	$page->appendChild( &$title( "Workflow View Screen - Details" ));
	$page->appendChild( $workflow_view_user_history_plugin->render() );

	# Admin tools view test.

	my $admin_tools_plugin = $session->plugin( "Screen::Admin" );

	$admin_tools_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/cgi/users/home",
		screenid => "Admin"
	);

	$page->appendChild( &$title( "Admin Screen" ));
	$page->appendChild( $admin_tools_plugin->render() );

	# Advanced search screen test.

	my $advanced_search_plugin = $session->plugin( "Screen::Search" );

	$advanced_search_plugin->{processor} = EPrints::ScreenProcessor->new(
		session => $session,
		url => $session->config( "base_url" ) . "/search/eprint/advanced",
		screenid => "Search"
	);

	$advanced_search_plugin->{processor}->{dataset} = $session->dataset( "eprint" );
	$advanced_search_plugin->{processor}->{searchid} = "advanced";

	$advanced_search_plugin->properties_from;
	$advanced_search_plugin->from;

	$page->appendChild( &$title( "Advanced Search Screen" ));
	$page->appendChild( $advanced_search_plugin->render() );

	return $page;	
}

1;