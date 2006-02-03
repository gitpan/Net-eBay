#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

sub usage {
  my ($msg) = @_;

  print STDERR "Error!  $msg \n\n
USAGE: $0 [--distance zipcode distance_in_miles] [--seller seller] terms
";
  exit 1;
}
my $eBay = new Net::eBay;

my ($seller, $zip, $distance, $category, $completed);

my $done = 0;
do {
  $done = 0;
  if( $ARGV[0] eq '--seller' ) {
    $done = 1;
    shift;
    $seller = shift;
  } elsif( $ARGV[0] eq '--category' ) {
    $done = 1;
    shift;
    $category = shift;
  } elsif( $ARGV[0] eq '--completed' ) {
    $done = 1;
    shift;
    $completed = 1;
  } elsif( $ARGV[0] eq '--distance' ) {
    $done = 1;
    shift;
    $zip = shift || usage "no zipcode";
    usage "bad zipcode '$zip'" unless $zip =~ /^\d+/;
    $distance = shift || usage "no distance";
    usage "bad distance '$distance'" unless $distance =~ /^\d+/;
  }
} while( $done && @ARGV);

my $query = join(" ", @ARGV );

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0, compatibility => 415 } );

my $request =
  {
   Query => $query
  };

if( defined $seller ) {
  $request->{UserIdFilter}->{IncludeSellers} = $seller;
}

if( defined $distance && defined $zip ) {
  $request->{ProximitySearch} = { MaxDistance => $distance, PostalCode => $zip };
}

my $result;
my $items;

$request->{CategoryID} = $category if(defined $category); 
$request->{SearchType} = 'Completed' if(defined $completed); 

$result = $eBay->submitRequest( "GetSearchResults", $request );
$items = $result->{SearchResultItemArray}->{SearchResultItem};


if( ref $result ) {
  if( $items ) { 
    $items = [$items] if( ref $items eq 'HASH' );
    foreach my $i (@$items) {
      my $item = $i->{Item};
      print "$item->{ItemID} ";


    my $endtime = $item->{ListingDetails}->{EndTime};
    $endtime =~ s/T/ /;
    $endtime =~ s/\.\d\d\d//;
    $endtime =~ s/Z/ GMT/;

    ############################################################
    # now figure out ending time in the LOCAL timezone
    # (not GMT and not necessarily California time)
    ############################################################
    my $local_endtime;
    {
      my $t1 = DateTime::Precise->new;
      $t1->set_from_datetime( $endtime );
      my $epoch = $t1->unix_seconds_since_epoch;
      my $t2 = DateTime::Precise->new;
      $t2->set_localtime_from_epoch_time( $epoch );
      #print "t1=" . $t1->asctime . " ($epoch) -> " . $t2->asctime . ".\n";
      $local_endtime = $t2->dprintf("%~M %D,%h:%m");
    }




      print sprintf( "%2d ", $item->{SellingStatus}->{BidCount} || 0 );
      print sprintf( "%25s ", $local_endtime );
      my $price = (0 &&defined $category
                   ? $item->{SellingStatus}->{CurrentPrice}
                   : $item->{SellingStatus}->{CurrentPrice}->{content} );
      print sprintf( "%7.2f ", $price );
      print " $item->{Title} ";
      print "\n";
    }
  } else {
    #print Dumper( $result );
  }
} else {
  print "Unparsed result: \n$result\n\n";
}

