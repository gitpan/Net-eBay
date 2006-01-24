#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

my $eBay = new Net::eBay;

my $done = 0;
do {
  $done = 0;
} while( $done );

my $query = join(" ", @ARGV );

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

my $result = $eBay->submitRequest( "GetSearchResults",
                                     {
                                      Query => $query
                                     }
                                   );
if( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";

  foreach my $i (@{$result->{SearchResultItemArray}->{SearchResultItem} }) {
    my $item = $i->{Item};
    print "$item->{ItemID} ";
    print sprintf( "%2d ", $item->{SellingStatus}->{BidCount} || 0 );
    print sprintf( "%7.2f ", $item->{SellingStatus}->{CurrentPrice}->{content} );
    print " $item->{Title} ";
    print "\n";
  }

} else {
  print "Unparsed result: \n$result\n\n";
}

