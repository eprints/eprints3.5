
######################################################################
#
# Dynamic Template
#
# If you use a dynamic template then this function is called every
# time a page is served to generate dynamic parts of it.
# 
# The dynamic template feature may be disabled to reduce server load.
#
# When enabling/disabling it, run 
# generate_apacheconf
# generate_static
# generate_views
# generate_abstracts
#
######################################################################

$c->{dynamic_template}->{enable} = 1;

# This method is called for every page to add/refine any parts that are
# specified in the template as <epc:pin ref="name" />

#$c->{dynamic_template}->{function} = sub {
#	my( $repository, $parts ) = @_;
#
#};

# Allow template parameter in the GET header to choose template used.
#$c->{allow_template_from_get} = 1;

# To support backwards-compatibility the new-style key tools plugins are
# included here
$c->{plugins}->{"Screen::Login"}->{appears}->{key_tools} = 100;
$c->{plugins}->{"Screen::Register"}->{actions}->{register}->{appears}->{key_tools} = 150;
$c->{plugins}->{"Screen::Logout"}->{appears}->{key_tools} = 10000;
$c->{plugins}->{"Screen::Admin::Config::Edit::XPage"}->{actions}->{edit}->{appears}->{key_tools} = 1250;
$c->{plugins}->{"Screen::Admin::Phrases"}->{actions}->{edit}->{appears}->{key_tools} = 1350;
$c->{plugins}->{"Screen::OtherTools"}->{appears}->{key_tools} = 20000;

=head1 COPYRIGHT AND LICENSE

=begin COPYRIGHT_AND_LICENSE

Copyright University of Southampton under the GNU Lesser General Public License. See README at https://github.com/eprints/eprints3.5 for further information.

EPrints 3.5 is supplied by EPrints Services.

=end COPYRIGHT_AND_LICENSE
