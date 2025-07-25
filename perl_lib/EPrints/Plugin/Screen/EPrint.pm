=head1 NAME

EPrints::Plugin::Screen::EPrint

=cut


package EPrints::Plugin::Screen::EPrint;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub properties_from
{
	my( $self ) = @_;

	$self->{processor}->{eprintid} = $self->{session}->param( "eprintid" );
	unless (defined $self->{processor}->{required_fields_only}) {
		$self->{processor}->{required_fields_only} = $self->{session}->param( "required_only" );
	}
	$self->{processor}->{eprint} = new EPrints::DataObj::EPrint( $self->{session}, $self->{processor}->{eprintid} );

	if( !defined $self->{processor}->{eprint} )
	{
		$self->{processor}->{screenid} = "Error";
		$self->{processor}->add_message( "error", $self->{session}->html_phrase(
			"cgi/users/edit_eprint:cant_find_it",
			id=>$self->{session}->make_text( $self->{processor}->{eprintid} ) ) );
		return;
	}

	$self->{processor}->{dataset} = $self->{processor}->{eprint}->get_dataset;

	$self->SUPER::properties_from;
}

sub could_obtain_eprint_lock
{
	my( $self ) = @_;

	return 0 unless defined $self->{processor}->{eprint};

	return $self->{processor}->{eprint}->could_obtain_lock( $self->{session}->current_user );
}

sub obtain_eprint_lock
{
	my( $self ) = @_;

	my $eprint = $self->{processor}->{eprint};
	return 0 unless defined $eprint;

	return 1 if $self->{processor}->{locked}->{$eprint};

	return $self->{processor}->{locked}->{$eprint} = $eprint->obtain_lock( $self->{session}->current_user );
}

sub allow
{
	my( $self, $priv ) = @_;

	return 0 unless defined $self->{processor}->{eprint};

	return 1 if( $self->{session}->allow_anybody( $priv ) );
	return 0 if( !defined $self->{session}->current_user );
	return $self->{session}->current_user->allow( $priv, $self->{processor}->{eprint} );
}

sub render_tab_title
{
	my( $self ) = @_;

	return $self->html_phrase( "title" );
}

sub render_title
{
	my( $self ) = @_;

	my $priv = $self->allow( "eprint/view" );
	my $owner  = $priv & 4;
	my $editor = $priv & 8;

	my $f = $self->{session}->make_doc_fragment;
	$f->appendChild( $self->html_phrase( "title" ) );
	$f->appendChild( $self->{session}->make_text( ": " ) );

	my $title = $self->{processor}->{eprint}->render_citation( "screen" );
	if( $owner && $editor )
	{
		$f->appendChild( $title );
	}
	else
	{
		my $a = $self->{session}->render_link( "?screen=EPrint::View&eprintid=".$self->{processor}->{eprintid} );
		$a->appendChild( $title );
		$f->appendChild( $a );
	}
	return $f;
}

sub redirect_to_me_url
{
	my( $self ) = @_;

	return $self->SUPER::redirect_to_me_url."&eprintid=".$self->{processor}->{eprintid};
}

sub register_furniture
{
	my( $self ) = @_;

	$self->SUPER::register_furniture;

	my $eprint = $self->{processor}->{eprint};
	my $user = $self->{session}->current_user;
	if( $eprint->is_locked )
	{
		my $my_lock = ( $eprint->get_value( "edit_lock_user" ) == $user->get_id );
		if( $my_lock )
		{
			#$self->{processor}->before_messages( $self->{session}->html_phrase( 
			#	"Plugin/Screen/EPrint:locked_to_you" ) );
		}
		else
		{
			$self->{processor}->add_message( "warning", $self->{session}->html_phrase( 
				"Plugin/Screen/EPrint:locked_to_other", 
				name => $eprint->render_value( "edit_lock_user" )) );
		}
	}

	return $self->{session}->make_doc_fragment;
}

sub register_error
{
	my( $self ) = @_;

	if( $self->{processor}->{eprint}->has_owner( $self->{session}->current_user ) )
	{
		$self->{processor}->add_message( "error", $self->{session}->html_phrase( 
			"Plugin/Screen/EPrint:owner_denied",
			screen=>$self->{session}->make_text( $self->{processor}->{screenid} ) ) );
	}
	else
	{
		$self->SUPER::register_error;
	}
}


sub workflow
{
	my( $self ) = @_;

	if( !defined $self->{processor}->{workflow} )
	{
		# look up and use the custom callback if its defined
		my $fn = $self->{session}->get_conf( "STAFF_ONLY_LOCAL_callback" );
                my $soa = ( defined $fn && ref $fn eq "CODE" ) ? &{$fn}( $self->{processor}->{eprint}, $self->{session}->current_user, "write" ) : 0;

		my $staff = $self->allow( "eprint/edit:editor" );
		my %opts = (
			item => $self->{processor}->{eprint},
			session => $self->{session},
			processor => $self->{processor},
			STAFF_ONLY => [$staff ? "TRUE" : "FALSE", "BOOLEAN"],
			STAFF_ONLY_LOCAL => [$soa ? "TRUE" : "FALSE", "BOOLEAN"],
		);
		
		my $user = $self->{session}->current_user;
                if( $user )
                {
                        foreach my $role ( $user->get_roles )
                        {
                                $role =~ s|/|__|g; # replace / with __
                                $opts{ "ROLE_" . $role } = [ "TRUE", "BOOLEAN" ];
                        }
                        $opts{ "ROLES" } = [ join("|", $user->get_roles), "STRING" ];
                }

 		$self->{processor}->{workflow} = EPrints::Workflow->new(
				$self->{session},
				$self->workflow_id,
				%opts
			);
	}

	return $self->{processor}->{workflow};
}

sub workflow_id
{
	return "default";
}

sub uncache_workflow
{
	my( $self ) = @_;

	delete $self->{session}->{id_counter};
	delete $self->{processor}->{workflow};
	delete $self->{processor}->{workflow_staff};
}

sub render_blister
{
	my( $self, $sel_stage_id ) = @_;

        my %item = (
                stages => [],
        );

	my $eprint = $self->{processor}->{eprint};
	my $session = $self->{session};

	my $workflow = $self->workflow;
	my $first = 1;
	my $selected = 0;
	my @stages = $workflow->get_stage_ids;
	if( $eprint->get_value( "eprint_status" ) eq "inbox" )
	{
		push @stages, "deposit";
	}
	foreach my $stage_id ( @stages )
	{
		my $phrase;
		if( $stage_id eq "deposit" )
		{
			$phrase = $session->phrase( "Plugin/Screen/EPrint:deposit" );
		}
		else
		{
			$phrase = $session->phrase( "metapage_title_".$stage_id );
		}
		$selected = $stage_id eq $sel_stage_id ? 1 : 0;
		push @{ $item{stages} }, { stage => $session->render_button(
			name  => "_action_jump_$stage_id", 
			value => $phrase,
			stage => 1,
			selected => $selected ), first => $first };

		$first = 0;
	}

	return $self->{repository}->template_phrase( "view:EPrints/Plugin/Screen/EPrint:render_blister", { item => \%item } );
}

sub hidden_bits
{
	my( $self ) = @_;

	return(
		$self->SUPER::hidden_bits,
		eprintid => $self->{processor}->{eprintid},
	);
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

