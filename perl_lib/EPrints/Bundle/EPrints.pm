package Bundle::EPrints;

$VERSION = 'v3.5.0';

1;

=head1 CONTENTS

BibTeX::Parser 1.05

CGI 4.68 - 2.56 was included in perl v5.6.0

Config::General 2.67

DBD::mysql 5.012 - This actually still has to be installed by package manager as the config seems to break when installed by cpan
DBI        1.647

Digest::MD5 2.59 - 2.16 was included in perl v5.7.3
Digest::SHA 6.04 - 5.32 was included in perl v5.9.3

File::BOM   0.18
File::Slurp 9999.32

HTTP::Headers       7.00
HTTP::Headers::Util 7.00

Image::ExifTool 13.25 - Only used by pdf_metadata which is currently an ingredient

IO::String 1.08

JSON 4.10

List::Util 1.68_01 - 1.06_00 was included in perl v5.7.3

LWP::MediaTypes      6.04
LWP::Protocol::https 6.14
LWP::Simple          6.78
LWP::UserAgent       6.78

MIME::Lite 3.033

Net::LDAP 0.68
Net::SMTP 3.15 - 2.21 was included in perl v5.7.3

Pod::Usage 2.05 - 1.12 was included in perl v5.6.0

Search::Xapian 1.2.25.5

Term::ReadKey 2.38

TeX::Encode 2.010

Text::Extract::Word 0.04
Text::Refer         1.106
Text::Unidecode     1.30
Text::Wrap          2024.001 - 98.112902 was included in perl v5.6.0

Time::HiRes 1.9764 - 1.20_00 was included in perl v5.7.3
Time::Seconds 1.36 - An unknown version was included in perl v5.9.5

Unicode::Collate - 0.10 was included in perl v5.7.3

URI          5.31
URI::OpenURL 0.4.6

XML::DOM              1.46
XML::LibXML           2.0210     - XML::LibXSLT 2.003000 - This is imported manually in cpan_modules.pl because it has to be run with notest
XML::NamespaceSupport 1.12
XML::Parser           2.47

YAML::Tiny            1.76

