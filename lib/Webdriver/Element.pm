#==
# Webdriver::Element
#
# Each instance of this class represents an element on a page.  We can send various element-level comments to
# any Webdriver::Element object.
#==
package Webdriver::Element;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

extends 'Webdriver::Component';

has '+agent' => (
    handles => {

        # Describe the identified element.
        describe => [ 'get_request_data', 'GET', '' ],

        # Search for an element on the page, starting from the identified element.
        set_element => [ 'get_request_data', 'POST', 'element' ],

        # Search for multiple elements on the page, starting from the identified element.
        set_elements => [ 'get_request_data', 'POST', 'elements' ],

        # Click on an element.
        click => [ 'get_request_data', 'POST', 'click' ],

        # Submit a FORM element.
        submit => [ 'get_request_data', 'POST', 'submit' ],

        # Returns the visible text for the element.
        get_text => [ 'get_request_data', 'GET', 'text' ],

        # Send a sequence of key strokes to an element.
        _set_value => [ 'get_request_data', 'POST', 'value', 'value' ],

        # Query for an element's tag name.
        get_name => [ 'get_request_data', 'GET', 'name' ],

        # Clear a TEXTAREA or text INPUT element's value.
        clear => [ 'get_request_data', 'POST', 'clear' ],

        # Determine if an OPTION element, or an INPUT element of type checkbox or radiobutton is currently selected.
        get_selected => [ 'get_request_data', 'GET', 'selected' ],

        # Determine if an element is currently enabled.
        get_enabled => [ 'get_request_data', 'GET', 'enabled' ],

        # Test if two element IDs refer to the same DOM element.
        # NOTE: NYI.
        # get_equals => ['get_request_data', 'GET', 'equals/:other'],

        # Determine if an element is currently displayed.
        get_displayed => [ 'get_request_data', 'GET', 'displayed' ],

        # Determine an element's location on the page.
        get_location => [ 'get_request_data', 'GET', 'location' ],

        # Determine an element's location on the screen once it has been scrolled into view.
        get_location_in_view => [ 'get_request_data', 'GET', 'location_in_view' ],

        # Determine an element's size in pixels.
        get_size => [ 'get_request_data', 'GET', 'size' ],
    }
);

## now define methods that don't work via the handles hash.

#==
# send_keys
#
# Send a set of keystrokes to this element.
#==
sub send_keys {
    my ( $self, $string ) = @_;

    $self->_set_value( [ split '', $string ] );
}

#==
# get_attribute
#
# Get the value of an element's attribute.
# Note that we can't use the handles href for this one, since we must build the command based on the input attribute.
# @param {string} attribute name
#==
sub get_attribute {
    my ( $self, $attr ) = @_;

    return $self->get_request_data( 'GET', "attribute/$attr" );
}

#==
# get_css_property
#
# Query the value of an element's computed CSS property.
#==
sub get_css_property {
    my ( $self, $prop ) = @_;

    return $self->get_request_data( 'GET', "css/$prop" );
}

__PACKAGE__->meta->make_immutable;

1;
