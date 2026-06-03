=head1 NAME

EPrints::Plugin::Screen::Admin::Config::Edit::XPage

=cut

package EPrints::Plugin::Screen::Admin::Config::Edit::XPage;

use EPrints::Plugin::Screen::Admin::Config::Edit::XML;

@ISA = ( 'EPrints::Plugin::Screen::Admin::Config::Edit::XML' );

use strict;

sub new
{
	my( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);
	
	$self->{appears} = [
# See cfg.d/dynamic_template.pl
#		{
#			place => "key_tools",
#			position => 1250,
#			action => "edit",
#		},
	];

	push @{$self->{actions}}, qw( edit );

	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;

	return $self->allow( "config/edit/static" );
}

sub allow_edit
{
	my( $self ) = @_;

	$self->{processor}->{conffile} ||= $self->{session}->get_static_page_conf_file;

	return defined $self->{processor}->{conffile};
}
sub action_edit {} # dummy action for key_tools

sub render_action_link
{
	my( $self, %opts ) = @_;

	my $conffile = $self->{processor}->{conffile};

	my $uri = URI->new( $self->{session}->current_url( path => 'cgi' , "users/home" ) );
	$uri->query_form(
		screen => substr($self->{id},8),
		configfile => $conffile,
	);

	$opts{uri} = $uri;
	$opts{link_title} = $self->{session}->html_phrase( "lib/session:edit_page" );
	return $self->SUPER::render_action_link( %opts );
}

1;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
