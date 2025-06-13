use Digest::MD5 qw( md5 );
use JSON;

$c->{subject_update_trigger} = sub
{
	my( %args ) = @_;
	my( $repo, $obj ) = @args{qw( repository dataobj )};

	my $datasetid = $obj->dataset->base_id;
	return unless $repo->config( 'history_enable', $datasetid );

	my %details_hash;
	for my $field (keys %{$obj->{changed}}) {
		$details_hash{$field} = [$obj->{changed}->{$field}, $obj->{data}->{$field}];
	}

	my $details = to_json( \%details_hash );
	my $rev_number = $obj->value( "rev_number" ) || 0;

	my $user = $repo->current_user;
	my $userid = defined $user ? $user->id : undef;

	# The object id is a string (like 'fac_eng') but the database expects an `SQL_INTEGER` (32 bit signed)
	# By hashing it first it doesn't matter that `unpack` will only take part of the string.
	my $object_id = unpack( 'l', md5( $obj->id ) );

	my $event = $repo->dataset( 'history' )->create_dataobj(
	{
		userid    => $userid,
		datasetid => $datasetid,
		objectid  => $object_id,
		revision  => $rev_number,
		action    => 'modify',
		details   => $details,
	});
};

$c->add_dataset_trigger( 'subject', EPrints::Const::EP_TRIGGER_AFTER_COMMIT, $c->{subject_update_trigger}, id => 'update_subject_history' );

$c->{history_enable}->{subject} = 1;

# Which fields should we show in the 'Subject History' and in what order
$c->{subject_history_fields} = ['depositable', 'name_name', 'name_sortvalue', 'name_lang', 'parents', 'ancestors', 'rev_number'];

