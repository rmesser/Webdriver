#==
# Webdriver::Component
#
# This is an abstract base class for any component used to communicate with a browser via the web driver protocol.
# Any component has-a Webdriver::Agent that handles the communication.  This class also has some base utility methods.
#==
package Webdriver::Component;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

use Webdriver::Agent;

use Try::Tiny;

has 'agent' => (
    is         => 'bare',
    isa        => 'Webdriver::Agent',
    lazy_build => 1,
    handles    => {
        send_request     => 'send_request',
        get_request_data => 'get_request_data',
    }
);

sub _build_agent {
    my $self = shift;
    return Webdriver::Agent->new( base_url => $self->get_base_url );
}

has 'base_url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

#==
# find_element
#
# The regular get_element will return data with the element_id in it.  This instead returns Webdriver::Element
# objects, which can then accept other commands.
#
# @param {hash} byname, OR a single css selector value.
# @param {string} .using the search strategy to use.  See specs for possible values.  The default is 'css selector',
#   which is generally (IMHO) the most flexible and useful search method.
# @param {string} .value the value of the search string.  Note that if we only receive one input, we use the default
#   "using" paramater and the sole input becomes the value parameter.
# @return {Webdriver::Element} the first matching element, if any.
#==
sub find_element {
    my ( $self, @params ) = @_;

    my %params = ( @params == 1 ) ? ( value => $params[0] ) : @params;
    $params{using} //= 'css selector';

    my $element;
    try {
        if ( my $data = $self->set_element(%params) ) {
            require Webdriver::Element;
            $element = Webdriver::Element->new( base_url => $self->get_base_url . '/element/' . $data->{ELEMENT} );
        }
    };

    return $element;
}

#==
# find_elements
#
# Similar to find_elements, but returns an array of element objects instead of just the first match.
# @param {hash} byname -- the same as find_element.
# @return {array} a list of Webdriver::Element objects
#==
sub find_elements {
    my ( $self, @params ) = @_;

    my %params = ( @params == 1 ) ? ( value => $params[0] ) : @params;
    $params{using} //= 'css selector';

    my @elements;
    try {
        my $data = $self->set_elements(%params);
        if ( ref $data eq 'ARRAY' ) {

            require Webdriver::Element;
            my $base_url = $self->get_base_url;

            foreach my $found_id (@$data) {

                push @elements, Webdriver::Element->new( base_url => "$base_url/element/$found_id->{ELEMENT}" );
            }
        }
    };

    return @elements;
}

__PACKAGE__->meta->make_immutable;

1;
