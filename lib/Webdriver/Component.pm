#==
# Webdriver::Component
#
# This is an abstract base class for any component used to communicate with a browser via the web driver protocol.
# Any component has-a Webdriver::Agent that handles the communication.  This class also has some base utility methods.
#==
package Webdriver::Component;
use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;

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

has 'locator_strategy' => (
    is => 'rw',
    isa =>
        enum( [ 'class name', 'css selector', 'id', 'name', 'link text', 'partial link text', 'tag name', 'xpath' ] ),
    default => 'css selector'
);

#==
# find_element
#
# The regular get_element will return data with the element_id in it.  This instead returns Webdriver::Element
# objects, which can then accept other commands.
#
# @param {hash} byname, OR a single value to use with our current locator_strategy.
# @param {string} .using the search strategy to use.  See specs for possible values.  The default is 'css selector',
#   which is generally (IMHO) the most flexible and useful search method.
# @param {string} .value the value of the search string.  Note that if we only receive one input, we use the current
#   locator_strategy and the sole input becomes the value parameter.
# @return {Webdriver::Element} the first matching element, if any.
#==
sub find_element {
    my ( $self, @params ) = @_;

    my @elements = $self->_find_elements( 1, @params );
    return $elements[0];
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

    return $self->_find_elements( 2, @params );
}

#==
# _find_elements
#
# Private method used by both find_element and find_elements.  Takes the same inputs as those, and also
# a leading $count param -- 1 to find just the first elements, or 2 to find more than one.
#==
sub _find_elements {
    my ( $self, $count, @params ) = @_;

    my %params = ( @params == 1 ) ? ( value => $params[0] ) : @params;
    my $locator_strategy = $self->get_locator_strategy;

    $params{using} //= $locator_strategy;

    my @elements;
    my $method = ( $count > 1 ) ? 'set_elements' : 'set_element';

    my $data = try {
        $self->$method(%params);
    }
    catch {
        my $error = $_;

        # if there is no such element, do nothing -- we return nothing, but don't die.  Other errors, we rethrow.
        if ( $error !~ /NoSuchElement/ ) {
            die $error;
        }
    };

    my @element_ids = ( $count > 1 && ref $data eq 'ARRAY' ) ? @$data : ( $count == 1 && ref $data ) ? ($data) : ();

    require Webdriver::Element;
    my $base_url = $self->get_base_url;

    foreach my $found_id (@element_ids) {

        push @elements,
            Webdriver::Element->new(
                base_url         => "$base_url/element/$found_id->{ELEMENT}",
                id               => $found_id->{ELEMENT},
                locator_strategy => $locator_strategy
            );
    }

    return @elements;
}

__PACKAGE__->meta->make_immutable;

1;
