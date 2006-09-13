#!/usr/bin/perl

use Net::eBay;
use Data::Dumper;

my $title = undef;
my $subtitle = undef;
my $price = undef;
my $quantity = undef;
my $category = undef;
my $bin = undef;
my $blockForeignBidders = undef;

my $item = undef;
if( -f 'item.txt' ) {
  $item = `cat item.txt`;
  chomp $item;
}

my $use_descr = 1;

my $done = 1;

sub get_argument {
  my ($name,$ref) = @_;
  if( $ARGV[0] eq "--$name" ) {
    shift @ARGV;
    $$ref = shift @ARGV;
    die "--$name requires an argument!" unless defined $$ref;
    return 1;
  }
  return undef;
}

while( $done ) {
  $done = 0;
  next if $done = get_argument( 'title', \$title );
  next if $done = get_argument( 'subtitle', \$subtitle );
  next if $done = get_argument( 'price', \$price );
  next if $done = get_argument( 'quantity', \$quantity );
  next if $done = get_argument( 'bin', \$bin );
  next if $done = get_argument( 'category', \$category );
  next if $done = get_argument( 'block-foreign-bidders', \$blockForeignBidders );

  if( $done = get_argument( 'item', \$item ) ) {
    $use_descr = undef;
    next;
  }
}

die "Need to have item number either from item.txt or from --item argument" unless defined $item;

die "invalid itemid '$item'" unless $item =~ /^\d+$/;

my $request = {
               Item => {
                        ItemID => $item,
                       },
              };



$request->{Item}->{Title}         = $title if ( $title ); 
$request->{Item}->{SubTitle}      = $subtitle if ( $subtitle ); 
$request->{Item}->{StartPrice}    = $price if ( $price ); 
$request->{Item}->{Quantity}      = $quantity if ( $quantity ); 
$request->{Item}->{BuyItNowPrice} = $bin if ( $bin ); 
$request->{Item}->{PrimaryCategory} = $category if ( $category ); 

$request->{Item}->{BuyerRequirements}->{MinimumFeedbackScore} = -1;
$request->{Item}->{BuyerRequirements}->{ShipToRegistrationCountry} = $blockForeignBidders if $blockForeignBidders;

if( $use_descr ) {
  die 'no file index.html' unless -f 'index.html';
  my $descr = `cat index.html`;
  $request->{Item}->{Description} = "<![CDATA[ $descr ]]>";
}

my $ebay = new Net::eBay;

my $result = $ebay->submitRequest( 'ReviseItem', $request );

if( ref $result ) {

  if( $result->{Errors} ) {
    print "FAILED!!!\n" . Dumper( $result ) . "\n\n";
    exit 1;
  }

  print "Succeeded!\n\n";

  my $total = 0;
  foreach my $fee (@{$result->{Fees}->{Fee}}) {
    my $amount = $fee->{Fee}->{content};
    
    next unless $amount > 0 && $fee->{Name} ne 'ListingFee';
    
    print "Fee: $fee->{Name}: $amount.\n";
    $total += $amount;
  }
  print "-----------------------------
TOTAL FEE: $total

";

} else {
  print "Failed: " . Dumper( $result ) . "\n";
}
