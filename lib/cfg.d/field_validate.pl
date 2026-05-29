######################################################################
# $field 
# - MetaField object
# $value
# - metadata value (see docs)
# $repository 
# - Repository object (the current repository)
# $for_archive
# - boolean (see comments at the start of the validation section)
#
# returns: @problems
# - ARRAY of DOM objects (may be null)
#
######################################################################
# Validate a particular field of metadata, currently used on users
# and eprints.
#
# This description should make sense on its own (i.e. should include 
# the name of the field.)
#
# The "required" field is checked elsewhere, no need to check that
# here.
#
######################################################################

$c->{validate_field} = sub
{
	my( $field, $value, $repository, $for_archive ) = @_;

	my $xml = $repository->xml();

	# only apply checks if the value is set
	return () if !EPrints::Utils::is_set( $value );

	my @problems = ();

	# CHECKS IN HERE

	my $values = ref($value) eq "ARRAY" ? $value : [$value];

	# closure for generating the field link fragment
	my $f_fieldname = sub {
		my $f = defined $field->property( "parent" ) ? $field->property( "parent" ) : $field;
		my $fieldname = $xml->create_element( "span", class=>"ep_problem_field:".$f->get_name );
		$fieldname->appendChild( $f->render_name( $repository ) );
		return $fieldname;
	};

	# Loop over actual individual values to check URLs, names and emails
	foreach my $v (@$values)
	{
		next unless EPrints::Utils::is_set( $v );

		if( $field->isa( "EPrints::MetaField::Url" ) )
		{
			# Valid URI check (very loose)
			if( $v !~ /^\w+:/ )
			{
				push @problems,
					$repository->html_phrase( "validate:missing_http",
						fieldname=>&$f_fieldname );
			}
		}
		elsif( $field->isa( "EPrints::MetaField::Name" ) )
		{
			# Check a name has a family part
			if( !EPrints::Utils::is_set( $v->{family} ) )
			{
				push @problems,
					$repository->html_phrase( "validate:missing_family",
						fieldname=>&$f_fieldname );
			}
			# Check a name has a given part
			elsif( !EPrints::Utils::is_set( $v->{given} ) )
			{
				push @problems,
					$repository->html_phrase( "validate:missing_given",
						fieldname=>&$f_fieldname );
			}
		}
		elsif( $field->isa( "EPrints::MetaField::Email" ) )
		{
			# Check an email looks "ok". Just checks it has only one "@" and no
			# spaces.
			if( $v !~ /^[^ \@]+\@[^ \@]+$/ )
			{
				push @problems,
					$repository->html_phrase( "validate:bad_email",
						fieldname=>&$f_fieldname );
			}
		}

		# Check for overly long values
		# Applies to all subclasses of Id: Text, Longtext, Url etc.
		if( $field->isa( "EPrints::MetaField::Id" ) )
		{
			if( EPrints::Utils::is_set( $v ) && length($v) > $field->property( "maxlength" ) )
			{
				push @problems,
					$repository->html_phrase( "validate:truncated",
						fieldname=>&$f_fieldname );
			}
		}

		# Unless duplicate usernames are explicitly permitted do not allow username to be changed to that of an existing user
		if ( $field->get_name eq "username" && $field->dataset->id eq "user" && defined $repository->param( 'dataobj' ) && !$repository->config( "allow_duplicate_usernames" ) )
		{
                      	my $user_with_username = EPrints::DataObj::User::user_with_username( $repository, $v );
			my $current_user = $field->dataset->dataobj( $repository->param( 'dataobj' ) );
                       	if ( $user_with_username->id ne $current_user->id )
                       	{
                        	push @problems, $repository->html_phrase( "validate:duplicate_username", username => $repository->make_text( $v ) );
               		}
		}
	}

	return( @problems );
};




=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
