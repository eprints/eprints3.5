######################################################################
#
# EP_TRIGGER_VALIDATE 'document' dataset trigger
#
######################################################################
# $dataobj 
# - Document object
# $repository 
# - Repository object (the current repository)
# $for_archive
# - Is this being checked to go live (`1` means it is)
# $problems
# - ARRAYREF of DOM objects
#
######################################################################
#
# Validate a document. validate_document_meta will be called auto-
# matically, so you don't need to duplicate any checks.
#
######################################################################

$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_VALIDATE, sub {
	my( %args ) = @_;
	my( $repository, $document, $problems ) = @args{qw( repository dataobj problems )};

	# "other" documents must have a description set
	if( $document->value( "format" ) eq "other" &&
	   !EPrints::Utils::is_set( $document->value( "formatdesc" ) ) )
	{
		my $fieldname = $repository->make_element( "span", class=>"ep_problem_field:documents" );
		push @$problems, $repository->html_phrase( 
					"validate:need_description" ,
					type=>$document->render_citation("brief"),
					fieldname=>$fieldname );
	}
}, id => 'other_without_description' );

$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_VALIDATE, sub {
	my( %args ) = @_;
	my( $repository, $document, $problems ) = @args{qw( repository dataobj problems )};

	# security can't be "public" if date embargo set
	if( !$repository->config( "retain_embargo_dates" ) && 
	    $document->value( "security" ) eq "public" &&
		EPrints::Utils::is_set( $document->value( "date_embargo" ) )
		)
	{
		my $fieldname = $repository->make_element( "span", class=>"ep_problem_field:documents" );
		push @$problems, $repository->html_phrase( 
					"validate:embargo_check_security" ,
					fieldname=>$fieldname );
	}
}, id => 'public_with_embargo' );

$c->add_dataset_trigger( 'document', EPrints::Const::EP_TRIGGER_VALIDATE, sub {
	my( %args ) = @_;
	my( $repository, $document, $problems ) = @args{qw( repository dataobj problems )};

	# embargo expiry date must be a full year, month and day and must be in the future
	if( EPrints::Utils::is_set( $document->value( "date_embargo" ) ) )
	{
		my $value = $document->value( "date_embargo" );
		my ($year, $month, $day) = split( '-', $value );
		my ($thisyear, $thismonth, $thisday) = EPrints::Time::get_date_array();

		if ( !EPrints::Utils::is_set( $month ) || !EPrints::Utils::is_set( $day ) )
		{
			my $fieldname = $repository->make_element( "span", class=>"ep_problem_field:documents" );
                        push @$problems, $repository->html_phrase( "validate:embargo_incomplete_date", fieldname=>$fieldname );
		}
		elsif ( !$repository->config( "retain_embargo_dates" ) )
		{
			if( $year < $thisyear || ( $year == $thisyear && $month < $thismonth ) ||
				( $year == $thisyear && $month == $thismonth && $day <= $thisday ) )
			{
				my $fieldname = $repository->make_element( "span", class=>"ep_problem_field:documents" );
				push @$problems,
					$repository->html_phrase( "validate:embargo_invalid_date",
					fieldname=>$fieldname );
			}
		}
		elsif ( $document->value( "security" ) eq "public" && ( $year > $thisyear || ( $year == $thisyear && $month > $thismonth ) || 
			( $year == $thisyear && $month == $thismonth && $day > $thisday ) ) )
		{
			my $fieldname = $repository->make_element( "span", class=>"ep_problem_field:documents" );
			push @$problems, $repository->html_phrase(
				"validate:embargo_check_security",
				fieldname=>$fieldname );
		}
	}
}, id => 'invalid_embargo' );

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

