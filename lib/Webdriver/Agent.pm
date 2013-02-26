#==
# Webdriver::Agent
#
# This is the class that handles communication with a web driver browser or java hub.  It is "dumb" in the sense
# that it knows nothing about the specific commands that might be sent.  It merely has a LWP::UserAgent
# and a JSON object.  Webdriver objects like a browser or an element each have an agent to handle communications.
# This class does know about error codes found here: http://code.google.com/p/selenium/wiki/JsonWireProtocol#Response_Status_Codes,
# and we throw a die with the summary version of code if we get one of those as status.
#==
package Webdriver::Agent;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

use LWP::UserAgent;
use JSON;
use Try::Tiny;

my $HTTP_INTERNAL_ERROR = 500;

has 'base_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_json_obj' => (
    is      => 'bare',
    lazy    => 1,
    default => sub { JSON->new->allow_nonref->utf8 },
    handles => {
        encode_json => 'encode',
        decode_json => 'decode',
    }
);

has '_user_agent' => (
    is         => 'bare',
    lazy_build => 1,
    handles    => { ua_request => 'request', }
);

sub _build__user_agent {
    LWP::UserAgent->new(
        default_headers => HTTP::Headers->new(
            Content_Type => 'application/json; charset=utf-8',
            Accept       => 'application/json'
        )
    );
}

# Error codes from spec:
my %ERROR_CODE = (
    6  => 'NoSuchDriver',
    7  => 'NoSuchElement',
    8  => 'NoSuchFrame',
    9  => 'UnknownCommand',
    10 => 'StaleElementReference',
    11 => 'ElementNotVisible',
    12 => 'InvalidElementState',
    13 => 'UnknownError',
    15 => 'ElementIsNotSelectable',
    17 => 'JavaScriptError',
    19 => 'XPathLookupError',
    21 => 'Timeout',
    23 => 'NoSuchWindow',
    24 => 'InvalidCookieDomain',
    25 => 'UnableToSetCookie',
    26 => 'UnexpectedAlertOpen',
    27 => 'NoAlertOpenError',
    28 => 'ScriptTimeout',
    29 => 'InvalidElementCoordinates',
    30 => 'IMENotAvailable',
    31 => 'IMEEngineActivationFailed',
    32 => 'InvalidSelector',
    33 => 'SessionNotCreatedException',
    34 => 'MoveTargetOutOfBounds',
);

#==
# send_request
#
# Send a request to the browser (or java hub).  Return a HTTP::Response object.  This is the base
# means of communicating and asking a browser to do something.
#
# @param {string} method, like GET or POST or DELETE
# @param {string} command -- could be any of the commands listed at http://code.google.com/p/selenium/wiki/JsonWireProtocol.
#   The command will be combined with the base_url for this object to form the full url.
# @param {hash} parameters to send with the command. These will be JSON-encoded before transmission as per the JSON wire
#    spec.
# @return {HTTP::Response} the raw response object upon success, or a false value on error.
#==
sub send_request {
    my ( $self, $method, $command, %params ) = @_;

    my $full_url = $self->get_base_url . ( $command ? "/$command" : '' );

    my $content = ( %params ) ? $self->encode_json( \%params ) : '';

    return $self->ua_request( HTTP::Request->new( $method, $full_url, undef, $content ) );
}

#==
# get_request_data
#
# Send request data and decode the JSON response and return it.  If we get no content to
# decode we'll just return nothing.
#==
sub get_request_data {
    my ( $self, $method, $command, @params ) = @_;

    if ( my $resp = $self->send_request( $method, $command, @params ) ) {

        my $content = $resp->content;
        if ( length $content ) {
            my $data = try {
                $self->decode_json( $resp->content );
            }
            catch {
                die 'Unable to decode content: ' . substr( $content, 0, 100 );
            };

            # status is expected to be 0 on success, so throw an error otherwise
            if ( $data->{status} > 0 ) {

                # use our list of defined errors, or if no match there, use the code from the HTTP::Response object
                my $code_desc = $ERROR_CODE{ $data->{status} } // $resp->code;
                die "Receieved error $code_desc from server";
            }

            # if all is well, return the value key from data
            return $data->{value};
        }

        # otherwise we have no content to decode, so just return nothing as long as we have success
        elsif ( $resp->is_success ) {
            return;
        }

        # here we have nothing to decode and an unsuccessful status, so die
        else {
            die 'Failed response: ' . $resp->message;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
