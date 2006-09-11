#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

my $nowatch = 0;

while( @ARGV ) {
  if( $ARGV[0] eq '--nowatch' ) {
    shift @ARGV;
    $nowatch = 1;
  } else {
    last;
  }
}

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
my $watching = 0;
my $items = 0;
if( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";

  print "   Item        W  B   Price Q   Title\n";
  #      7551933377   0  0   49.99 1 Siliconix Transistor tester IPT II 2 Monitor

  my $items = $result->{ActiveList}->{ItemArray}->{Item};
  $items = [$items] unless (ref $items) =~ /^ARRAY/;
  my $count = 0;
  foreach my $item (@$items) {
    $items++;
    unless( defined $item->{ItemID} ) {
      print STDERR "Error! No ItemID!\n" . Dumper( $result ) . "\n\n";
      exit 1;
    }
    
    print "$item->{ItemID} ";
    if( $nowatch ) {
      print "    ";
    } else {
      print sprintf( "%3d ", $item->{WatchCount} || 0 );
    }
    $watching += $item->{WatchCount} || 0;
    print sprintf( "%2d ", $item->{SellingStatus}->{BidCount} || 0 );
    print sprintf( "%7.2f ", $item->{SellingStatus}->{CurrentPrice}->{content} );
    print "$item->{Quantity} $item->{Title} ";
    print "\n";

    $count++;
  }

  if( !$nowatch ) {
    print "$count items, $result->{SellingSummary}->{AuctionBidCount} bids, $watching watchers\n";
  }
} else {
  print STDERR "Unparsed result: \n$result\n\n";
  exit 1;
}

exit 0;