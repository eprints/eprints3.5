package Bundle::EPrints;

$VERSION = 'v3.5.0';

1;

=head1 CONTENTS

BibTeX::Parser 1.05

Config::General 2.67

DBI        1.647

File::BOM   0.18
File::Slurp 9999.32

HTTP::Headers       7.00
HTTP::Headers::Util 7.00

Image::ExifTool 13.25 - Used by PDF metadata import and sometimes used for thumbnails

IO::String 1.08

JSON 4.10

LWP::MediaTypes      6.04
LWP::Protocol::https 6.14 - Used by DataCite to register DOIs
LWP::Simple          6.78
LWP::UserAgent       6.78

MIME::Lite 3.033

Net::LDAP 0.68

Search::Xapian 1.2.25.5

Term::ReadKey 2.38

TeX::Encode 2.010 - Used by BibTeX export

Text::Extract::Word 0.04
Text::Refer         1.106 - Used by EndNote import
Text::Unidecode     1.30

URI          5.31
URI::OpenURL 0.4.6

XML::DOM              1.46
XML::LibXML           2.0210
XML::NamespaceSupport 1.12
XML::Parser           2.47

YAML::Tiny            1.76


=head1 OTHER PACKAGES

=head2 These packages aren't installed by this file for various reasons but must be installed by other means

DBD::mysql 5.012 - This has to be installed by the package manager to get the config right

XML::LibXSLT 2.003000 - This is installed separately in cpan_modules.pl because it has to be run with notest


=head1 CORE PERL PACKAGES

=head2 These packages are included in a baseline Perl version of v5.16.1 (CentOS/RHEL 7)

Carp 1.26 - Latest is 1.50

CGI 3.59 - Latest is 4.68

Cwd 3.39_02 - Latest is 3.75

Data::Dumper 2.135_06 - Latest is 2.183

Digest::MD5 2.51 - Latest is 2.59
Digest::SHA 5.71 - Latest is 6.04

English 1.05 - Latest is 1.11

Fcntl 1.11           - Latest is 1.18
File::Basename 2.84  - Latest is 2.84
File::Compare 1.1006 - Latest is 1.1008
File::Copy 2.23      - Latest is 2.41
File::Find 1.20      - Latest is 1.44
File::Path 2.08_01   - Latest is 2.18
File::stat 1.05      - Latest is 1.14
File::Temp 0.22      - Latest is 0.2311
FileHandle 2.02      - Latest is 2.05

FindBin 1.51 - Latest is 1.54

Getopt::Long 2.38 - Latest is 2.58

HTTP::Tiny 0.017 - Latest is 0.090

List::Util 1.25 - Latest is 1.68_01

MIME::Base64 3.13 - Latest is 3.16

Net::SMTP 2.31 - Latest is 3.15

Pod::Usage 1.51 - Latest is 2.05

POSIX 1.30 - Latest is 1.97

Scalar::Util 1.25 - Latest is 1.69

Storable 2.34 - Latest is 3.25

Sys::Hostname 1.15 - Latest is 1.25

Text::Wrap 2009.0305 - Latest is 2024.001

Time::HiRes 1.9725 - Latest is 1.9764
Time::Local 1.2000 - Latest is 1.35
Time::Piece 1.20_01 - Latest is 1.36
Time::Seconds undef - Latest is 1.36

Unicode::Collate 0.89 - Latest is 1.31

