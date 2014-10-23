package Net::eBay;

use warnings;
use strict;

use XML::Simple;
use XML::Dumper;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;
use HTTP::Status qw(status_message);
use HTTP::Date qw(time2str str2time);
use Carp qw( croak );

use vars qw( $_ua );

=head1 NAME

Net::eBay - Perl Interface to XML based eBay API. 

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

This module helps user to easily execute queries against eBay's XML API.

=head2 Getting Official Time

 use Net::eBay;
 my $eBay   = new Net::eBay; # look up ebay.ini in $ENV{EBAY_INI_FILE}, "./ebay.ini", "~/.ebay.ini"
 my $result = $eBay->submitRequest( "GeteBayOfficialTime", {} );
 print "eBay Official Time = $result->{EBayTime}.\n";

=head2 Automated bidding

eBay does not allow bidding via eBay API.

=head2 Listing Item for sale

 use Net::eBay;
 use Data::Dumper;

 # another way of creating Net::eBay object.
 my $ebay = new Net::eBay( {
                              SiteLevel => 'prod',
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

See an alternative example of submitting an item using New Schema, in script
ebay-add-item.pl.

If an error in parsing XML occurs, result will be simply the string
that is the text representation of the answer.

=head1 EXPORT

new -- creates eBay API. Requires supplying of credentials:
DeveloperKey, ApplicationKey, CertificateKey, Token. Net::eBay will
not be created until these keys and the token are supplied.

Get them by registering at http://developer.ebay.com and self
certifying. Celf certifying is a trivial process of solemnly swearing
that you are ready to use their API.

The SiteLevel parameter is also mandatory and can be either 'prod' or
'dev'. prod means to use their production site (being charged real
money for listings, etc), and dev means to use eBay sandbox
http://sandbox.ebay.com/.

Parameters can be supplied in two ways:

1) As a hash table

2) As a filename (only argument). If filename and hash are missing, Net::eBay
makes an effort to fine a ebay.ini file by looking for: $ENV{EBAY_INI_FILE}, ./ebay.ini,
~/.ebay.ini . That's the default constructor.

See SAMPLE.ebay.ini in this distribution.

=head1 Defaults and XML API Versions

This module, by default, is using the "Legacy XML API" that is set to
expire in the summer of 2006. That default will change as the legacy
API actually expires.

XML API Schema is set by calling setDefaults( { ... } )

See its documentation below.

=head1 ebay.ini FILE

ebay.ini is a file that lists ebay access keys and whether this is for
accessing eBay production site or its developers' sandbox. Example of
the file (see SAMPLE.ebay.ini):

 # dev or prod
 SiteLevel=prod

 # your developer key
 DeveloperKey=KLJHAKLJHLKJHLKJH

 # your application key
 ApplicationKey=LJKGHKLJGKJHG

 # your certificate key
 CertificateKey=SUYTYWTKWTYIUYTWIUTY

 # your token (a very BIG string)
 Token=JKHGHJGJHGKJHGKJHGkluhsdihdsriuhfwe87yr8wehIEWH9O78YWERF90HF9UHJESIPHJFV94Y4089734Y

=for html This module was seen <IMG SRC="http://www.algebra.com/cgi-bin/counter.mpl?key=Net__Ebay"> times.

=head1 FUNCTIONS

=head2 new

=cut

sub new {
  my ($type, $hash) = @_;

  unless( $hash ) {
    if( defined $ENV{EBAY_INI_FILE} && -f $ENV{EBAY_INI_FILE} ) {
      $hash = $ENV{EBAY_INI_FILE};
    } elsif( defined $ENV{HOME} && -f "$ENV{HOME}/.ebay.ini" ) {
      $hash = "$ENV{HOME}/.ebay.ini";
    } elsif( -f "ebay.ini" ) {
      $hash = "ebay.ini";
    }
  }

  unless( $hash ) {
    warn "Error creating Net::eBay: no hash with keys and no ini file in: \$ENV{EBAY_INI_FILE}, ~/.ebay.ini, ./ebay.ini. eBay requires these keys. See perldoc Net::eBay on the keys file.\n";
    return undef;
  }

  unless(ref $hash) {
    # this is a filename
    open( F, $hash ) || croak "Cannot open Net::eBay resource file $hash";
    my $h = {};
    while( my $l = <F> ) {
      next if $l =~ /^\s*$/;
      next if $l =~ /\s*\#/;
      next unless $l =~ /^\s*(\w+)\s*\=\s*(.*)/;
      $h->{$1} = $2;
    }
    close( F );
    $hash = $h;
  }
  
  bless $hash, $type;

  $hash->{debug} = undef unless $hash->{debug};
  
  $hash->{siteid} = 0 unless $hash->{siteid};

  # We use eBay Legacy API (expires in summer of 2006) by default.
  $hash->{defaults} = { API => 1 };
  
  return undef unless verifyAndPrint( defined $hash->{SiteLevel} && $hash->{SiteLevel},
                                      "SiteLevel must be defined" );
  
  if( $hash->{SiteLevel} eq 'prod' ) {
    $hash->{url} = 'https://api.ebay.com/ws/api.dll';
  } elsif( $hash->{SiteLevel} eq 'dev' ) {
    $hash->{url} = 'https://api.sandbox.ebay.com/ws/api.dll';
  } else {
    return unless verifyAndPrint( 0, "Parameter SiteLevel is not defined or is wrong: '$hash->{SiteLevel}'" );
  }

  $hash->{siteid} = 0 unless $hash->{siteid};
  
  return undef unless verifyAndPrint( $hash->{DeveloperKey}, "'DeveloperKey' field must be defined with eBay Developer key");
  return undef unless verifyAndPrint( $hash->{ApplicationKey}, "'ApplicationKey' field must be defined with eBay application key");
  return undef unless verifyAndPrint( $hash->{CertificateKey}, "'CertificateKey' field must be defined with eBay certificate key");
  return undef unless verifyAndPrint( $hash->{Token}, "'Token' field must be defined with eBay token");

  $hash->{SessionCertificate} = "$hash->{DeveloperKey};$hash->{ApplicationKey};$hash->{CertificateKey}";
  
  return $hash;
}


=head2 setDefaults

Sets application defaults, most importantly the XML API version to be used.

Takes a hash argument.

The following defaults can be set:

* API -- sets eBay API version. Only two values are supported: '1' means
Legacy API set to expire in the summer of 2006, '2' means the API that
supersedes it. All other values are illegal.

* debug -- if debug is set to true, prints a lot of debugging information, XML sent and received etc.

Example:

  $eBay->setDefaults( { API => 2 } ); # use new eBay API
  $eBay->setDefaults( { API => 2, debug => 1 } ); # use new eBay API and also debug all calls

=cut

sub setDefaults {
  my ($this, $defaults) = @_;

  if( defined $defaults->{API} ) {
    my $api = $defaults->{API};
    if( $api != 1 && $api != 2 ) {
      croak "Incorrect value of API ($api) is supplied in the hash. Use API => 1 or API => 2.";
    }
    my $old = $this->{defaults}->{API};
    $this->{defaults}->{API} = $api;

  }

  $this->{debug} = $defaults->{debug} if defined $defaults->{debug};
  
}

=head2 submitRequest

Sends a request to eBay. Takes a name of the API call and a hash of arguments.
The arguments can be hashes of hashes and are properly translated into nested
XML structures.

Example:

  TopLevel => {
                Item1 => 'hello',
                Item2 => 'world'
                Item3 => ['foo', 'bar']
              }

it would be translated to

  <TopLevel>
    <Item1>hello</Item1>
    <Item2>world</Item2>
    <Item3>foo</Item3>
    <Item3>bar</Item3>
  </TopLevel>

If an argument has XML attributes and should be formatted like this:

 <TestAttribute currencyID="USD" >abcd</TestAttribute>

(note "currencyID")

your argument should be

 TestAttribute => { _attributes => { currencyID => 'USD' }, _value => 'abcd' ),

Depending on the default API set by setDefaults (see above), XML
produced will be compatible with the eBay API version selected by the
user.

=cut

sub submitRequest {
  my ($this, $name, $request) = @_;

  my $req = HTTP::Request->new( POST => $this->{url} );
  $req->header( 'X-EBAY-API-SITEID', $this->{siteid} );
  $req->header( 'X-EBAY-API-DEV-NAME', $this->{DeveloperKey} );
  $req->header( 'X-EBAY-API-DETAIL-LEVEL', '2' );
  $req->header( 'X-EBAY-API-CERT-NAME', $this->{CertificateKey} );
  $req->header( 'X-EBAY-API-APP-NAME', $this->{ApplicationKey} );
  $req->header( 'Content-Type', 'text/xml' );
  $req->header( 'X-EBAY-API-SESSION-CERTIFICATE', $this->{SessionCertificate} ); 

  my $xml = "";
  if( $this->{defaults}->{API} == 1 ) {
    $req->header( 'X-EBAY-API-COMPATIBILITY-LEVEL', '349' );
    $req->header( 'X-EBAY-API-CALL-NAME', $name );

    $request->{Verb} = $name unless $request->{Verb};
    
    $xml = "<?xml version='1.0' encoding='UTF-8'?>
<request>
    <RequestToken>" . $this->{Token} . "</RequestToken>\n";

    $xml .= hash2xml( 2, $request );
    
    $xml .= "</request>\n\n";
    
  } elsif( $this->{defaults}->{API} == 2 ) {
    $req->header( 'X-EBAY-API-COMPATIBILITY-LEVEL', '391' );
    $req->header( 'X-EBAY-API-CALL_NAME', $name );

    $xml = "
<?xml version='1.0' encoding='utf-8'?>
 <$name"."Request xmlns=\"urn:ebay:apis:eBLBaseComponents\">
 <RequesterCredentials>
   <eBayAuthToken>$this->{Token}</eBayAuthToken>
 </RequesterCredentials>
" . hash2xml( 2, $request ) . "
</$name"."Request>
";

  } else {
    croak "Strange, the default API '$this->{defaults}->{API}' is unrecognized. BUG.\n";
  }

  $req->content( $xml );

  if( $this->{debug} ) {
    print STDERR "XML:\n$xml\n";
    print STDERR "Request: " . $req->as_string;
  }

  my $res = $_ua->request($req);
  return undef unless $res;

  if( $this->{debug} ) {
    print STDERR "Content (debug of Net::eBay): " . $res->content . "\n";
  }
  
  $@ = "";
  my $result = undef;
  eval {
    $result = XMLin( $res->content );
    #print "perl result=$result.\n";
  };

  return $result if $result;
  
  print STDERR "Error parsing XML ($@). \n";
  return $res->content;
}

=head2 officialTime

Returns eBay official time

=cut

sub officialTime {
  my ($this) = @_;
  my $result = $this->submitRequest( "GeteBayOfficialTime", {} );
  if( $result ) {
    return $result->{EBayTime} if( $this->{defaults}->{API} == 1 );
    return $result->{Timestamp} if( $this->{defaults}->{API} == 2 );
    croak "Strange, unknown API level '$this->{defaults}->{API}'. bug\n";
  } else {
    print STDERR "Could not get official time.\n";
    return undef;
  }
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
  my ($depth, $request, $optionalKey) = @_;

  my $r = ref $request;
  
  unless( ref $request ) {
    my $data = $request;
    $data =~ s/\</\&lt\;/g;
    $data =~ s/\>/\&gt\;/g;
    return $data;
  }

  my $xml;
  
  if( $r =~ /HASH/ ) {
    if( defined $request->{_value} && defined $request->{_attributes} ) {
      $xml = "<$optionalKey ";
      foreach my $a ( sort keys %{$request->{_attributes}} ) {
        #print STDERR "a=$a.\n";
        $xml .= "$a=\"$request->{_attributes}->{$a}\" ";
      }
      $xml .= ">";
      $xml .= hash2xml( $depth+2, $request->{_value} );
      $xml .= "</$optionalKey>";
    } else {
      $xml = "\n";
      my $d = " " x $depth;
      foreach my $key (sort keys %$request) {
        my $r = $request->{$key};
        if( (ref( $r ) =~ /HASH/)
            && defined $r->{_value}
            && defined $r->{_attributes} ) {
          $xml .= "$d  " . hash2xml( $depth+2, $r, $key ) . "\n";
        } else {
          my $data = hash2xml( $depth+2, $request->{$key}, $key );
          $xml .= "$d  <$key>$data</$key>\n";
        }
      }
      $xml .= "$d";
    }
  } elsif( $r =~ /ARRAY/ ) {
    foreach my $item ( @$request ) {
      $xml .= hash2xml( $depth+2, { $optionalKey => $item }, $optionalKey );
    }
  }
  
  return $xml;
}


$_ua = LWP::UserAgent->new( agent => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.1.4322)" );
$_ua->timeout( 50 );


1; # End of Net::eBay
