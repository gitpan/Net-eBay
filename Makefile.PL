use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Net::eBay',
              AUTHOR              => 'Igor Chudov <ichudov@algebra.com>',
              VERSION_FROM        => 'lib/Net/eBay.pm',
              ABSTRACT            => 'XML based communication with eBay API',
              PL_FILES            => {},
              EXE_FILES           => [ 'ebay-official-time.pl', 'ebay-validate-test-user.pl',
                                       'ebay-get-categories.pl', 'ebay-add-item.pl'
                                     ],
              PREREQ_PM => {
                            'Test::More' => 0,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Net-eBay-*' },
);
