#==
# Webdriver::Browser::Test
#
# This package adds some testing methods to the Webdriver::Browser module.  For example:
#
#   use Webdriver::Browser::Test;
#
#   # get your browser object as usual, and you can run test methods below like this:
#   $browser->element_text_like('h1', qr/my heading/, "H1 contents test");
#
#==
use strict;
use warnings;

use Webdriver::Browser;

package Webdriver::Browser;
use Test::More;

#==
# element_exists
#
# Test if the element is found based on the input search values.
#==
sub element_exists {
    my ( $self, @params ) = @_;

    ok( $self->find_element(@params), $self->_get_element_desc(@params) . ' exists' );
}

#==
# _get_element_desc
#
# Return a name based on element search inputs.  The inputs can be the one argument form or a
# hash with using and value, hence the logic below.
#==
sub _get_element_desc {
    my ( $self, @params ) = @_;
    return ( @params == 1 ) ? "element $params[0]" : do { my %p = @params; "element $p{value}" };
}

#==
# field_value_is
#
# Test that the input field has the expected value.
# @param {string} field_name
# @param {any} expected_value -- an aref for a field with multiple values, or a scalar for all others
# @param {string} test name (optional) if not passed, we do a hopefully reasonable default.
#==
sub field_value_is {
    my ( $self, $field_name, $expected_value, $test_name ) = @_;

    my $actual_val = $self->get_field_value($field_name);

    $test_name //= "$field_name value";

    # Use is_deeply because we could have an aref for checkbox questions.  If we don't then is_deeply acts
    # just like "is" anyway.
    is_deeply( $actual_val, $expected_value, $test_name );
}

#==
# element_text_is
#
# Find an element based on a search string, then test whether the text is the expected value.
#==
sub element_text_is {
    my ( $self, $element_search, $expected_text, $test_name ) = @_;

    my $actual_text = $self->get_element_text($element_search);
    $test_name //= "element $element_search text";

    is( $actual_text, $expected_text, $test_name );
}

#==
# element_text_like
#
# Find an element based on a search string, then test whether the text matches the input regexp.
#==
sub element_text_like {
    my ( $self, $element_search, $expected_re, $test_name ) = @_;

    my $actual_text = $self->get_element_text($element_search);
    $test_name //= "element $element_search text matches $expected_re";

    like( $actual_text, $expected_re, $test_name );
}

#==
# body_text_like
#
# Like element_text_like, but automatically tests the body element.
#==
sub body_text_like {
    my ( $self, $expected_re, $test_name ) = @_;

    $test_name //= "body text matches $expected_re";
    $self->element_text_like( 'body', $expected_re, $test_name );
}

#==
# attribute_is
#
# Find an element using the input search string, then test that the attribute given has the expected value.
#==
sub attribute_is {
    my ( $self, $element_search, $attr, $expected, $test_name ) = @_;

    $test_name //= "element $element_search $attr attribute";
    if ( my $el = $self->find_element($element_search) ) {
        my $actual_attr = $el->get_attribute($attr);

        is( $actual_attr, $expected, $test_name );
    }
    else {
        fail("$test_name -- element not found");
    }
}

1;
