#==
# Webdriver::Server
#
# Initiate contact with the browser or java hub, and start sessions.  Example usage:
#
#  # communicate with a web driver enabled browser on local port 9515
#  my server = Webdriver::Server->new( port => 9515 );
#  my $browser = $server->get_new_browser(); # start a new session
#  $browser->set_url('http://wikipedia.org'); # browse to a url
#
#==
package Webdriver::Server;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

extends 'Webdriver::Component';

use Webdriver::Browser;

my $HTTP_INTERNAL_ERROR = 500;

has 'port' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 4444,    # the typical selenium port
);

has 'host' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'localhost',
);

has 'scheme' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http',
);

has 'base_url' => (
    is     => 'rw',
    isa    => 'Str',
    writer => '_set_base_url',
);

# now the server that controls a browser can either be a Selenium server, or just a browser driver
# like chromedriver or phantomjs with ghostdriver.  The user can pass in this indicator, or if not
# set we'll send a test request to /wd/hub, the starting point for the Selenium server.  If we get an
# OK response we know we're talking to selenium.
has 'is_selenium' => (
    isa       => 'Bool',
    reader    => 'is_selenium',
    writer    => '_set_is_selenium',
    predicate => 'has_is_selenium',
);

has '+agent' => (
    handles => {

        # Query the server's current status.
        get_status => [ 'get_request_data', 'GET', 'status' ],

        # Returns a list of the currently active sessions.
        get_sessions => [ 'get_request_data', 'GET', 'sessions' ],
    }
);

sub BUILD {
    my $self = shift;

    return if defined $self->get_base_url;

    # define base url, unless the caller has set it explicitly (which is not encouraged)
    my $base_url = $self->get_scheme . '://' . $self->get_host . ':' . $self->get_port;

    if ( $self->_test_for_selenium($base_url) ) {
        $base_url .= '/wd/hub';
    }
    $self->_set_base_url($base_url);
}

#==
# _test_for_selenium
#
# Test for whether or not we are talking to a selenium server.  Or if the user told us in the constructor,
# or we've already tested, just return that.
#==
sub _test_for_selenium {
    my ( $self, $base_url ) = @_;

    if ( not $self->has_is_selenium ) {

        my $resp = LWP::UserAgent->new->get("$base_url/wd/hub");
        $self->_set_is_selenium( $resp->is_success );
    }
    return $self->is_selenium;
}

#==
# get_new_browser
#
# Get a new Webdriver::Browser object.
# @param {hash} byname
# @param {href} .desiredCapabilities (optional) the list of capabilities needed, as defined in spec.
# @param {href} .requiredCapabilities (optional) the list of capabilities needed, as defined in spec.
# @param {Webdriver::Browser} a browser session object
#==
sub get_new_browser {
    my ( $self, %params ) = @_;

    my $dc = $params{desiredCapabilities}  // {};
    my $rc = $params{requiredCapabilities} // {};

    # ask for a new session.  the response is expected to have a location header with the session id
    my $resp = $self->send_request( 'POST', 'session', desiredCapabilities => $dc, requiredCapabilities => $rc );

    if ( $resp and my $location = $resp->headers->header('location') ) {

        # This location could either be a full url, or a url to be appended to our base, so we need to check it
        my $session_url = ( $location =~ /^http/ ) ? $location : $self->get_base_url . $location;

        return Webdriver::Browser->new( base_url => $session_url );
    }
    else {
        die( $resp ? $resp->message : 'No response to request for a new browser session.' );
    }
}

__PACKAGE__->meta->make_immutable;

1;
