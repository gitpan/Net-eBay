#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 1 } );

###########################################################################
# safety check to make sure that you do not do something stupid and pay $$$
#
if( $eBay->{SiteLevel} ne 'dev' ) {
  print "Warning, you are trying to do something that will COST YOU MONEY!
Submitting test auctions to live ebay site will cost you about a dollar or so.
Listing fees are NOT REFUNDABLE!

To cancel, press Control-C, or hit ENTER to continue.
";
  my $dummy = <STDIN>;
}

######################################################################
# now, the actual work
my $result = $eBay->submitRequest( "AddItem",
                                   {
                                    Item =>
                                    {
                                     Title => 'Test Item created with Net::eBay perl module L@@K NR',
                                     BuyItNowPrice => 9.99,
                                     Country => 'US',
                                     Currency => 'USD',
                                     Description => "
<P>For sale is a <FONT COLOR=RED SIZE=+2><B>Like New Test Item</B></FONT>.
<FONT SIZE=-1>Has rust and numerous dents</FONT>. Sold AS IS.</P>

<P>
  This listing was submitted using the New Schema: <CODE>\$eBay->setDefaults( { API => 2 } );</CODE>
</P>

<P>For information on Net::eBay perl module that created this listing, see
http://search.cpan.org/~ichudov/</P>

",
                                     ListingDuration => 'Days_7',
                                     Location => 'Tulsa, OK',
                                     PaymentMethods => 'PayPal',
                                     PayPalEmailAddress => 'you@example.com',
                                     PrimaryCategory => { CategoryID => 14111 },
                                     Quantity => 1,
                                     TestAttribute => {
                                                       _value => "abcd",
                                                       _attributes => { currencyID => 'USD' }
                                                      },
                                     TestVector => [ qw( foo bar baz ) ],
                                     RegionID => 0,
                                     StartPrice => 0.99,
                                    }
                                   }
                                 );
if( ref $result ) {
  print "Result: " . Dumper( $result ) . "\n";
} else {
  print "Unparsed result: \n$result\n\n";
}
