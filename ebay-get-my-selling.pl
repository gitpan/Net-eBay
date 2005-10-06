#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

#my $seller = shift @ARGV || die "Usage: $0 seller-id";

my $result = $eBay->submitRequest( "GetMyeBaySelling",
                                   {
                                    ActiveList => {
                                                   Sort => 'TimeLeft',
                                                   Pagination => {
                                                                  EntriesPerPage => 100,
                                                                  PageNumber => 1
                                                                 }
                                                  }
                                   }
                                 );
if( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";

  foreach my $item (@{$result->{ActiveList}->{ItemArray}->{Item}}) {
    print "$item->{ItemID} $item->{Quantity} $item->{Title} ";
    print "$item->{WatchCount}w " if$item->{WatchCount};
    print "(\$$item->{SellingStatus}->{CurrentPrice}->{content}";
    print ", $item->{SellingStatus}->{BidCount} bids" if $item->{SellingStatus}->{BidCount};
    print ")";
    print "\n";
  }

  print "$result->{SellingSummary}->{AuctionBidCount} bids\n";
} else {
  print "Unparsed result: \n$result\n\n";
}

