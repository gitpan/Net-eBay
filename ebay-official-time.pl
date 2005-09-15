#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
my $eBay = new Net::eBay;
$eBay->setDefaults( { API => 2 } );

print "eBay Official time = " . $eBay->officialTime . "\n";
