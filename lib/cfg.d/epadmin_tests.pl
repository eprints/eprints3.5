$c->add_trigger( EP_TRIGGER_EPADMIN_TEST, sub
{
	my( %args ) = @_;
	
	my $repo = $args{repository};

    # check for configuration using methods removed from Apache2.4
    if( !Apache2::Connection->can( 'remote_ip' ) && defined $repo->config( "can_request_view_document" ) )
    {
        local $Data::Dumper::Deparse=1;
		use Data::Dumper;
        if( Dumper( $repo->config( "can_request_view_document" ) ) =~ /connection\S+remote_ip/i )
        {
            print "EPrints warning! '".$repo->get_id."' uses 'remote_ip' in the 'can_request_view_document' configuration, but this version of Apache does not have that method. This may lead to the security value for a document being ignored. Please check configuration.\n";
        }
    }

	return EP_TRIGGER_OK;
}, id => 'check_apache_remote_ip' );
