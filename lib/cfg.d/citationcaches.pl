# Enable citation caching
$c->{citation_caching}->{enabled} = 1;

# CitationCache Dataset
$c->{datasets}->{citationcache} = {
        class => "EPrints::DataObj::CitationCache",
        sqlname => "citationcache",
        index => 0,
};

# Exclude specific data objects from caching
$c->{citation_caching}->{excluded_dataobjs} = [
	'loginticket',
	'subject',
];

# Exclude specific citation styles from caching
$c->{citation_caching}->{excluded_styles} = [
        'result',
];
