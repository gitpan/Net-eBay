package Net::eBay;

use warnings;
use strict;

use XML::Simple;
use XML::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status qw(status_message);
use HTTP::Date qw(time2str str2time);

use vars qw( $_ua );

=head1 NAME

Net::eBay - Perl Interface to XML based eBay API. 

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

Example of listing an item for sale:

use Net::eBay;
use Data::Dumper;

my $ebay = new Net::eBay( {
                              site_level => 'prod',
                              DeveloperKey => '...',
                              ApplicationKey => '...',
                              CertificateKey => '...',
                              Token => '...',
                             } ); 

my $result = $ebay->submitRequest( "AddItem",
                      {
                       DetailLevel => "0",
                       ErrorLevel => "1",
                       SiteId = > "0",
                       Verb => "  AddItem",
                       Category => "14111",
                       CheckoutDetailsSpecified => "0",
                       Country => "us",
                       Currency => "1",
                       Description => "For sale is like new <A HREF=http://www.example.com/jhds/>thingamabob</A>.Shipping is responsibility of the buyer.",
                       Duration => "7",
                       Location => "Anytown, USA, 43215",
                       Gallery => 1,
                       GalleryURL => 'http://igor.chudov.com/images/mark_mattson.jpg',
                       MinimumBid => "0.99",
                       BuyItNowPrice => 19.99,
                       PayPalAccepted => "1",
                       PayPalEmailAddress => "ichudov\@example.com",
                       Quantity => "1",
                       Region => "60",
                       Title => "Igor's Item with Gallery xaxa",
                      }
                    );

  print "Result: " . Dumper( $result ) . "\n";

Result of submitRequest is a perl hash obtained from the response XML using XML::Simple, something like this:

Result: $VAR1 = {
          'Item' => {
                    'Id' => '4503546598',
                    'Fees' => {
                              'FeaturedGalleryFee' => '0.00',
                              'InternationalInsertionFee' => '0.00',
                              'CurrencyId' => '1',
                              'GalleryFee' => '0.25',
                              'AuctionLengthFee' => '0.00',
                              'ProPackBundleFee' => '0.00',
                              'BorderFee' => '0.00',
                              'FeaturedFee' => '0.00',
                              'SchedulingFee' => '0.00',
                              'HighLightFee' => '0.00',
                              'FixedPriceDurationFee' => '0.00',
                              'PhotoDisplayFee' => '0.00',
                              'ListingFee' => '0.55',
                              'BuyItNowFee' => '0.00',
                              'PhotoFee' => '0.00',
                              'GiftIconFee' => '0.00',
                              'SubtitleFee' => '0.00',
                              'InsertionFee' => '0.30',
                              'ListingDesignerFee' => '0.00',
                              'BoldFee' => '0.00',
                              'ReserveFee' => '0.00',
                              'CategoryFeaturedFee' => '0.00'
                            },
                    'StartTime' => '2005-08-30 04:50:47',
                    'EndTime' => '2005-09-06 04:50:47'
                  },
          'EBayTime' => '2005-08-30 04:50:47'
        };



=head1 EXPORT

new -- creates eBay API. Requires supplying of credentials:
DeveloperKey, ApplicationKey, CertificateKey, Token. Net::eBay will
not be created until these keys and the token are supplied.

Get them by registering at http://developer.ebay.com and self
certifying. Celf certifying is a trivial process of solemnly swearing
that you are ready to use their API.

The site_level parameter is also mandatory and can be either 'prod' or
'dev'. prod means to use their production site (being charged real
money for listings, etc), and dev means to use eBay sandbox
http://sandbox.ebay.com/.


=head1 FUNCTIONS

=head2 function1

=cut

sub new {
  my ($type, $hash) = @_;
  bless $hash, $type;
  $hash->{siteid} = 0 unless $hash->{siteid};
  if( $hash->{site_level} eq 'prod' ) {
    $hash->{url} = 'https://api.ebay.com/ws/api.dll';
  } elsif( $hash->{site_level} eq 'dev' ) {
    $hash->{url} = 'https://api.sandbox.ebay.com/ws/api.dll';
  } else {
    return unless verifyAndPrint( 0, "Parameter site_level is not defined or is wrong: '$hash->{site_level}'" );
  }

  $hash->{siteid} = 0 unless $hash->{siteid};
  
  return undef unless verifyAndPrint( $hash->{DeveloperKey}, "'DeveloperKey' field must be defined with eBay Developer key");
  return undef unless verifyAndPrint( $hash->{ApplicationKey}, "'ApplicationKey' field must be defined with eBay application key");
  return undef unless verifyAndPrint( $hash->{CertificateKey}, "'CertificateKey' field must be defined with eBay certificate key");
  return undef unless verifyAndPrint( $hash->{Token}, "'Token' field must be defined with eBay token");

  $hash->{SessionCertificate} = "$hash->{DeveloperKey};$hash->{ApplicationKey};$hash->{CertificateKey}";
  
  return $hash;
}


=head2 function2

=cut

sub submitRequest {
  my ($this, $name, $request) = @_;

  my $req = HTTP::Request->new( POST => $this->{url} );
  $req->header( 'X-EBAY-API-SITEID', $this->{siteid} );
  $req->header( 'X-EBAY-API-DEV-NAME', $this->{DeveloperKey} );
  $req->header( 'X-EBAY-API-DETAIL-LEVEL', '2' );
  $req->header( 'X-EBAY-API-CERT-NAME', $this->{CertificateKey} );
  $req->header( 'X-EBAY-API-APP-NAME', $this->{ApplicationKey} );
  $req->header( 'X-EBAY-API-COMPATIBILITY-LEVEL', '349' );
  $req->header( 'X-EBAY-API-CALL-NAME', $name );
  $req->header( 'Content-Type', 'text/xml' );
  $req->header( 'X-EBAY-API-SESSION-CERTIFICATE', $this->{SessionCertificate} ); 



  my $xml = "<?xml version='1.0' encoding='UTF-8'?>
<request>
    <RequestToken>" . $this->{Token} . "</RequestToken>\n";

  $xml .= hash2xml( 2, $request );
  
  $xml .= "</request>\n\n";

  $req->content( $xml );
  
  #print "XML:\n$xml\n";
  #print "Request: " . $req->as_string;

  my $res = $_ua->request($req);
  return undef unless $res;

  #print "Content: " . $res->content . "\n";
  my $result = XMLin( $res->content );
  #print "perl result=$result.\n";
  return $result;
}


=head1 AUTHOR

Igor Chudov, C<< <ichudov@algebra.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ebay@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-eBay>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Igor Chudov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

sub verifyAndPrint {
  my ($cond, $text) = @_;
  print STDERR "Error in Net::eBay: $text.\n" unless $cond;
  return $cond;
}

sub hash2xml {
  my ($depth, $request) = @_;
  unless( ref $request ) {
    my $data = $request;
    $data =~ s/\</\&lt\;/g;
    $data =~ s/\>/\&gt\;/g;
    return $data;
  }

  my $xml = "\n";
  my $d = " " x $depth;
  foreach my $key (sort keys %$request) {
    my $data = hash2xml( $depth+2, $request->{$key} );
    $xml .= "$d  <$key>$data</$key>\n";
  }
  $xml .= "$d";
  return $xml;
}


$_ua = LWP::UserAgent->new( agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.1.4322)" );
$_ua->timeout( 50 );


1; # End of Net::eBay
