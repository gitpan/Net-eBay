#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

my $usage = "Usage: $0 item-id feedback text";
die $usage unless @ARGV;

my ($detail, $debug);

my $done;

do {
  $done = 0;
} while( $done );


my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

my $item = shift @ARGV or die $usage;

my $text = join( ' ', @ARGV ) or die $usage;

my $result = $eBay->submitRequest( "GetItem",
                                   {
                                    ItemID => $item
                                   }
                                 );
if( ref $result ) {
  if( $debug ) {
    print "Result: " . Dumper( $result ) . "\n";
  }
  
  my $high_bidder = $result->{Item}->{SellingStatus}->{HighBidder}->{UserID};
  
  if( $high_bidder ) {
    my $fb = {
              ItemID => $item,
              TargetUser => $high_bidder,
              CommentType => 'Positive',
              CommentText => $text
             };

    my $fbresult = $eBay->submitRequest( "LeaveFeedback",
                                         $fb );

    print Dumper( $fbresult );
  }
} else {
  print "Unparsed result: \n$result\n\n";
}

