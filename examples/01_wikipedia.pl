#!/usr/bin/env perl
use strict;
use warnings;

# This file tests retrieving a web page, submitting a page via key entry, and
# then checking search results.
#
# This assumes a webdriver server or selenium server is running somewhere.

use Test::More tests => 4;

use Webdriver::Server;

# this is an example of connecting directly to chromedriver and getting a browser
my $server = Webdriver::Server->new( port => 9515 );
my $browser = $server->get_new_browser;

# or below is an example connection to selenium server, and then asking for a browser of a particular type:
# my $server = Webdriver::Server->new( port => 4444, host => 'my.selenium.server' );
# my $browser = $server->get_new_browser( desiredCapabilities => {browserName => 'firefox'} );


ok( $browser->isa('Webdriver::Browser'), "browser driver object created" );

$browser->set_url('http://wikipedia.org');

is( $browser->get_title, "Wikipedia", "title test" );

$browser->set_keys("testing\n");

my $element = $browser->find_element( using => 'css selector', value => 'li' );
ok( $element->isa('Webdriver::Element'), "element created" );

# note the below could change if wikipedia search results change
like( $element->get_text, qr/assessment/i, "element text match" );

$browser->close;
