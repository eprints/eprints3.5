$c->{rate_limit}->{enabled} = 0;
$c->{rate_limit}->{max_secs} = 60; # Total duration of all requests for a specific IP address should be less than 60 seconds (factoring in depreciation of older requests durations).
$c->{rate_limit}->{depreciate_secs} = 60; # Every 60 seconds the total requests duration for each specific IP address should be depreciated.
$c->{rate_limit}->{depreciate_factor} = 0.5; # Total request durations for each specific IP should be halved when they are depreciated.
$c->{rate_limit}->{allow_ips} = []; # Some IPs will not be rate limited.

