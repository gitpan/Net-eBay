#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;
use Getopt::Long;

my $usage = "Usage: $0 item-id{,item-id} feedback text\nNote:no spaces between item ids, ONLY COMMAS";

die $usage unless @ARGV;

my ($detail, $debug);

GetOptions(
           "debug!" => \$debug,
           );

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

my $items = shift @ARGV || die $usage;

foreach my $item ( split( /,/, $items ) ) {

  die $usage unless $item =~ /^\d+$/;
  
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
      
      print "$item ($result->{Item}->{Title}): $fbresult->{Ack}\n";
      unless( $fbresult->{Ack} eq 'Success' ) {
        #print Dumper( $fbresult );
        print "Why: $fbresult->{Errors}->{LongMessage}\n";
      } else {
        print STDERR "Success! $high_bidder $item <-- $text\n";
      }
    } else {
      print STDERR "Item $item not found.\n";
    }
  } else {
    print "Unparsed result: \n$result\n\n";
  }
}
