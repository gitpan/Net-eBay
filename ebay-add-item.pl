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

sub addItem {
  my $args = shift @_;
  my $description = $args->{Description} || die "No description supplied to AddItem";
  
  my $request =
    {
     Item =>
     {
      #BuyItNowPrice => 6.0,
      Title => ($args->{Title} || die "No title supplied to AddItem"),
      Country => $args->{Country} || "US",
      Currency => $args->{Currency} || "USD",
      Description => "<![CDATA[ $description ]]>", 
      ListingDuration => $args->{ListingDuration} || "Days_7",
      Location => $args->{Location} || "Lisle, IL, 60532", 
      PaymentMethods => $args->{PaymentMethods} || 'PayPal',
      PayPalEmailAddress => ($args->{PayPalEmailAddress} || 'myaddress@foobar.com'),
      PrimaryCategory => {
                          CategoryID => $args->{Category} || die "No category supplied to AddItem",
                         },
      Quantity => $args->{Quantity} || 1,
      RegionID => 0,
      StartPrice => ($args->{StartPrice} || die "No start price supplied to AddItem"),
     }
    };
  
  $request->{Item}->{BuyItNowPrice} = $args->{BuyItNowPrice} if $args->{BuyItNowPrice};
  
  my $result = $eBay->submitRequest( "AddItem", $request );
  
  if( ref $result ) {
    print "Result: " . Dumper( $result ) . "\n";
    return $result;
  } else {
    print "Unparsed result: \n$result\n\n";
  }
}

addItem( { Title => 'foo bar',
           Description => 'Almost new foobar no BIN',
           StartPrice => '9.97',
           Category => 1504,
           #BuyItNowPrice => 12,
           PayPalEmailAddress => 'ichudov@algebra.com',
         }
       );
