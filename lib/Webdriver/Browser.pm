#==
# Webdriver::Browser
#
# This encapsulates a session with a browser.  Note that the JsonWireProtocol page specs refer to this as a session,
# not a browser.  We use the class name ::Browser because this module has most of the commands for going to a url,
# searching for elements on a page, submitting a page, and so on.
#==
package Webdriver::Browser;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

extends 'Webdriver::Component';

use Webdriver::Window;

has '+agent' => (
    handles => {

        # Below, we create methods for each of the session commands described in the spec
        # at http://code.google.com/p/selenium/wiki/JsonWireProtocol.  The descriptions and commands were copy/pasted
        # verbatim from the spec, and then run through a script to produce the method names, with some manual tweaks.
        # The method naming and argument passing rules are as follows:
        #
        #  1. For each GET command, map to get_$command.  For example, there is GET /url command, so we have a get_url.
        #  2. For each POST command that takes arguments, map to set_$command.  For example, there is a POST /url that
        #     accepts a url as input, so we have a set_url method here.
        #  3. If the POST command accepts no inputs, name it by the command alone.  For example, /back is a POST
        #     without any inputs, so we have a 'back' method here for that.
        #  4. If the command has slashes, like timeouts/async_script, change those to underscores, so that becomes
        #     set_timeouts_async_script.
        #  5. Expect named args in the format defined in the spec.  However, if there is only one named arg, we instead
        #     accept that input by position as the first and only input.  For example, for set_url, the input defined
        #     in the spec is {url => $url}, but since there is only one input, we allow simply
        #     $session->set_url('http://foo.com').  Hence the 'url' part appears in the curried handle below for set_url.
        #  6. For each DELETE command, map to delete_$command.
        #  7. For the commands that expect a sequence of keys as an aref, instead accept a normal string and
        #     automatically convert that to an aref.  Make the method that accepts the aref a private method.
        #
        # Exceptions such as 'get_capabilities' and 'close' are needed because the command urls are empty, so we
        # choose descriptive names not necessarily based on the spec.
        #
        # Also see below for extra methods and helper methods in addition to the set that maps directly to the
        # protocol.

        # Retrieve the capabilities of the specified session.
        get_capabilities => [ 'get_request_data' => 'GET', '' ],

        # Delete the session.
        close => [ 'get_request_data' => 'DELETE', '' ],

        # Configure the amount of time that a particular type of operation can execute for before they are aborted and a |Timeout| error is returned to the client.
        set_timeouts => [ 'get_request_data', 'POST', 'timeouts' ],

        # Set the amount of time, in milliseconds, that asynchronous scripts executed by /session/:sessionId/execute_async are permitted to run before they are aborted and a |Timeout| error is returned to the client.
        set_timeouts_async_script => [ 'get_request_data', 'POST', 'timeouts/async_script', 'ms' ],

        # Set the amount of time the driver should wait when searching for elements.
        set_timeouts_implicit_wait => [ 'get_request_data', 'POST', 'timeouts/implicit_wait', 'ms' ],

        # Retrieve the current window handle.
        get_window_handle => [ 'get_request_data', 'GET', 'window_handle' ],

        # Retrieve the list of all window handles available to the session.
        get_window_handles => [ 'get_request_data', 'GET', 'window_handles' ],

        # Retrieve the URL of the current page.
        get_url => [ 'get_request_data', 'GET', 'url' ],

        # Navigate to a new URL.
        set_url => [ 'get_request_data', 'POST', 'url', 'url' ],

        # Navigate forwards in the browser history, if possible.
        forward => [ 'get_request_data', 'POST', 'forward' ],

        # Navigate backwards in the browser history, if possible.
        back => [ 'get_request_data', 'POST', 'back' ],

        # Refresh the current page.
        refresh => [ 'get_request_data', 'POST', 'refresh' ],

        # Inject a snippet of JavaScript into the page for execution in the context of the currently selected frame.
        execute => [ 'get_request_data', 'POST', 'execute' ],

        # Inject a snippet of JavaScript into the page for execution in the context of the currently selected frame.
        execute_async => [ 'get_request_data', 'POST', 'execute_async' ],

        # Take a screenshot of the current page.
        get_screenshot => [ 'get_request_data', 'GET', 'screenshot' ],

        # List all available engines on the machine.
        get_ime_available_engines => [ 'get_request_data', 'GET', 'ime/available_engines' ],

        # Get the name of the active IME engine.
        get_ime_active_engine => [ 'get_request_data', 'GET', 'ime/active_engine' ],

        # Indicates whether IME input is active at the moment (not if it's available.
        get_ime_activated => [ 'get_request_data', 'GET', 'ime/activated' ],

        # De-activates the currently-active IME engine.
        ime_deactivate => [ 'get_request_data', 'POST', 'ime/deactivate' ],

        # Make an engines that is available (appears on the listreturned by getAvailableEngines) active.
        set_ime_activate => [ 'get_request_data', 'POST', 'ime/activate', 'engine' ],

        # Change focus to another frame on the page.
        set_frame => [ 'get_request_data', 'POST', 'frame' ],

        # Change focus to another window.
        set_window => [ 'get_request_data', 'POST', 'window' ],

        # Close the current window.
        delete_window => [ 'get_request_data', 'DELETE', 'window' ],

        # Retrieve all cookies visible to the current page.
        get_cookie => [ 'get_request_data', 'GET', 'cookie' ],

        # Set a cookie.
        set_cookie => [ 'get_request_data', 'POST', 'cookie' ],

        # Delete all cookies visible to the current page.
        # Note that this method name deviates from our standard rules.
        delete_all_cookies => [ 'get_request_data', 'DELETE', 'cookie' ],

        # Get the current page source.
        get_source => [ 'get_request_data', 'GET', 'source' ],

        # Get the current page title.
        get_title => [ 'get_request_data', 'GET', 'title' ],

        # Search for an element on the page, starting from the document root.
        set_element => [ 'get_request_data', 'POST', 'element' ],

        # Search for multiple elements on the page, starting from the document root.
        set_elements => [ 'get_request_data', 'POST', 'elements' ],

        # Get the element on the page that currently has focus.
        ## TODO: convert to an ::Element object
        element_active => [ 'get_request_data', 'POST', 'element/active' ],

        # Send a sequence of key strokes to the active element.
        _set_keys => [ 'get_request_data', 'POST', 'keys', 'value' ],

        # Get the current browser orientation.
        get_orientation => [ 'get_request_data', 'GET', 'orientation' ],

        # Set the browser orientation.
        set_orientation => [ 'get_request_data', 'POST', 'orientation', 'orientation' ],

        # Gets the text of the currently displayed JavaScript alert(), confirm(), or prompt() dialog.
        get_alert_text => [ 'get_request_data', 'GET', 'alert_text' ],

        # Sends keystrokes to a JavaScript prompt() dialog.
        set_alert_text => [ 'get_request_data', 'POST', 'alert_text', 'text' ],

        # Accepts the currently displayed alert dialog.
        accept_alert => [ 'get_request_data', 'POST', 'accept_alert' ],

        # Dismisses the currently displayed alert dialog.
        dismiss_alert => [ 'get_request_data', 'POST', 'dismiss_alert' ],

        # Move the mouse by an offset of the specificed element.
        set_moveto => [ 'get_request_data', 'POST', 'moveto' ],

        # Click any mouse button (at the coordinates set by the last moveto command).
        set_click => [ 'get_request_data', 'POST', 'click', 'button' ],

        # Click and hold the left mouse button (at the coordinates set by the last moveto command).
        set_buttondown => [ 'get_request_data', 'POST', 'buttondown', 'button' ],

        # Releases the mouse button previously held (where the mouse is currently at).
        set_buttonup => [ 'get_request_data', 'POST', 'buttonup', 'button' ],

        # Double-clicks at the current mouse coordinates (set by moveto).
        doubleclick => [ 'get_request_data', 'POST', 'doubleclick' ],

        # Single tap on the touch enabled device.
        set_touch_click => [ 'get_request_data', 'POST', 'touch/click', 'element' ],

        # Finger down on the screen.
        set_touch_down => [ 'get_request_data', 'POST', 'touch/down' ],

        # Finger up on the screen.
        set_touch_up => [ 'get_request_data', 'POST', 'touch/up' ],

        # Finger move on the screen.
        set_touch_move => [ 'get_request_data', 'POST', 'touch/move' ],

        # Scroll on the touch screen using finger based motion events.
        set_touch_scroll => [ 'get_request_data', 'POST', 'touch/scroll' ],

        # Scroll on the touch screen using finger based motion events.
        set_touch_scroll => [ 'get_request_data', 'POST', 'touch/scroll' ],

        # Double tap on the touch screen using finger motion events.
        set_touch_doubleclick => [ 'get_request_data', 'POST', 'touch/doubleclick', 'element' ],

        # Long press on the touch screen using finger motion events.
        set_touch_longclick => [ 'get_request_data', 'POST', 'touch/longclick', 'element' ],

        # Flick on the touch screen using finger motion events.
        set_touch_flick => [ 'get_request_data', 'POST', 'touch/flick' ],

        # Flick on the touch screen using finger motion events.
        set_touch_flick => [ 'get_request_data', 'POST', 'touch/flick' ],

        # Get the current geo location.
        get_location => [ 'get_request_data', 'GET', 'location' ],

        # Set the current geo location.
        set_location => [ 'get_request_data', 'POST', 'location', 'location' ],

        # Get all keys of the storage.
        get_local_storage => [ 'get_request_data', 'GET', 'local_storage' ],

        # Set the storage item for the given key.
        set_local_storage => [ 'get_request_data', 'POST', 'local_storage' ],

        # Clear the storage.
        delete_local_storage => [ 'get_request_data', 'DELETE', 'local_storage' ],

        # Get the storage item for the given key.  NYI.
        # get_local_storage_key_:key => ['get_request_data', 'GET', 'local_storage/key/:key'],

        # Remove the storage item for the given key.  NYI.
        # delete_local_storage_key_:key => ['get_request_data', 'DELETE', 'local_storage/key/:key'],

        # Get the number of items in the storage.
        get_local_storage_size => [ 'get_request_data', 'GET', 'local_storage/size' ],

        # Get all keys of the storage.
        get_session_storage => [ 'get_request_data', 'GET', 'session_storage' ],

        # Set the storage item for the given key.
        set_session_storage => [ 'get_request_data', 'POST', 'session_storage' ],

        # Clear the storage.
        delete_session_storage => [ 'get_request_data', 'DELETE', 'session_storage' ],

        # Get the storage item for the given key. NYI.
        # get_session_storage_key_:key => ['get_request_data', 'GET', 'session_storage/key/:key'],

        # Remove the storage item for the given key. NYI.
        # delete_session_storage_key_:key => ['get_request_data', 'DELETE', 'session_storage/key/:key'],

        # Get the number of items in the storage.
        get_session_storage_size => [ 'get_request_data', 'GET', 'session_storage/size' ],

        # Get the log for a given log type.
        set_log => [ 'get_request_data', 'POST', 'log', 'type' ],

        # Get available log types.
        get_log_types => [ 'get_request_data', 'GET', 'log/types' ],

        # Get the status of the html5 application cache.
        get_application_cache_status => [ 'get_request_data', 'GET', 'application_cache/status' ],

    }
);

## now we define some extra methods in cases where handles aren't sufficient.

#==
# send_keys
#
# The spec says do a POST to "/keys" to send key strokes, so by our naming convention that would be 'set_keys', which
# isn't a very descriptive name.  Plus you must pass keys as an array, which is awkward.  So we have this method
# to take a string and send it to the browser, to the currently active element.  (See send_element_keys for sending
# keys to a particular element.)
#==
sub send_keys {
    my ( $self, $string ) = @_;

    $self->_set_keys( [ split '', $string ] );
}


#==
# delete_cookie
#
# Delete the cookie with the given name.
# @param {string} the cookie name
#==
sub delete_cookie {
    my ( $self, $cookie_name ) = @_;

    return $self->get_request_data( 'DELETE', "cookie/$cookie_name" );
}

#==
# get_window
#
# Get a Webdriver::Window object for the current window.
#==
sub get_window {
    my $self          = shift;
    my $window_handle = $self->get_window_handle;

    return Webdriver::Window->new( base_url => $self->get_base_url . "/window/$window_handle" );
}

#==
# get_windows
#
# Get a list of Webdriver::Window objects, one for each available in this session.
#==
sub get_windows {
    my $self = shift;

    my @windows;
    my $handles  = $self->get_window_handles;
    my $base_url = $self->get_base_url;

    foreach my $handle (@$handles) {
        push @windows, Webdriver::Window->new( base_url => "$base_url/window/$handle" );
    }

    return @windows;
}

#==============================================================================
# Element Methods
#
# The methods in this section are short-cuts for find_element plus an action.  For example, insetad of saying
#   $browser->find_element('#element_id')->click();
#
# You can say:
#   $browser->click_element('#element_id');
#
# So not that much of a win, but still these are easy methods to write so might as well have them.
#==

#==
# _run_element_method
#
# This is the core method used below, to find an element and then call an input method on it with the given inputs.
#==
sub _run_element_method {
    my ( $self, $method, $search_value, @params ) = @_;

    if ( my $element = $self->find_element($search_value) ) {
        return $element->$method(@params);
    }
}

# The delegation and currying feature in Moose (handles) are great for defining one method in terms of another,
# like we do with the agent handles at the top of this package.  But here we want to curry to $self, and there's
# no way to do that, as far as I know, without an attribute.  So this is a bit odd, but here we create a circular
# attribute just so we can build a set of simple element methods via the handles hashref.
has '_self' => (
    is       => 'bare',
    weak_ref => 1,
    default  => sub {shift},
    handles  => {
        click_element                => [ '_run_element_method', 'click' ],
        submit_element               => [ '_run_element_method', 'submit' ],
        clear_element                => [ '_run_element_method', 'clear' ],
        get_element_text             => [ '_run_element_method', 'get_text' ],
        get_element_name             => [ '_run_element_method', 'get_name' ],
        get_element_location         => [ '_run_element_method', 'get_location' ],
        get_element_location_in_view => [ '_run_element_method', 'get_location_in_view' ],
        get_element_size             => [ '_run_element_method', 'get_size' ],
        get_element_selected         => [ '_run_element_method', 'get_selected' ],
        get_element_enabled          => [ '_run_element_method', 'get_enabled' ],
        get_element_displayed        => [ '_run_element_method', 'get_displayed' ],
        send_element_keys            => [ '_run_element_method', 'send_keys' ],
    }
);

#==
# moveto_element
#
# Move the cursor to the specified element, if found.  You can also include an optional x and y offset.
# For example:
#   $browser->moveto_element('div.myclass'); # move the cursor to the center of the first div.myclass element.
# or with an offset:
#   $browser->moveto_element('li.green', xoffset => 10, yoffset => -23);
#==
sub moveto_element {
    my ( $self, $search_value, %params ) = @_;

    if ( my $el = $self->find_element($search_value) ) {
        $params{element} = $el->get_id;
        $self->set_moveto(%params);
    }
}

#==
# doubleclick_element
#
# Double click an element found via the input search string.
#
# @params{string} a search string, using the input locator strategy
#==
sub doubleclick_element {
    my ( $self, $search_value ) = @_;

    # note that the webdriver protocol provides no direct way to doubleclick an element, so we
    # have to move to its location, then send a doubleclick.
    if ( $self->moveto_element($search_value) ) {
        $self->doubleclick;
    }
}

#==
# drag_and_drop
#
# Drag one element to another element.  Example usage:
#  $browser->drag_and_drop(from => 'div.someclass', to => 'div#my_target');
#
# @param {hash} byname
# @param {string} .from a search string for the element to move
# @param {string} .to a search string for the element to move to
#==
sub drag_and_drop {
    my ( $self, %params ) = @_;
    my $from = $params{from};
    my $to   = $params{to};

    $self->moveto_element($from);
    $self->buttondown();
    $self->moveto_element($to);
    $self->buttonup();
}

#==
# End of element methods
#==============================================================================

#==
# submit
#
# Submit the first form element found on a page.
#==
sub submit {
    my $self = shift;
    if ( my $form = $self->find_element( using => 'css selector', value => 'form' ) ) {
        $form->submit();
    }
}

#==
# set_fields
#
# Given a hash, set multiple fields on the current window.  Example usage:
#   $browser->set_fields(Q1 => 2, username => 'somebody', CB => [2,3,'foo']);
#
# For each input key, we'll look for an input field with that name.
#==
sub set_fields {
    my ( $self, %params ) = @_;

    # even if the user has selected a different locator strategy, in this method we want to default to
    # 'css selector', so use local for that.  Not exactly as clean as using our setter method, but easier anyway.
    local $self->{locator_strategy} = 'css selector';

    while ( my ( $field, $value ) = each %params ) {

        # first look for any select, input, or textarea element with the given name
        my $w_name = qq|[name="$field"]|;
        my @inputs = $self->find_elements("input$w_name,select$w_name,textarea$w_name");

        next if not @inputs;

        my $type = $inputs[0]->get_attribute('type');

        # if this is a checkbox, first uncheck all so that we'll be left only with inputs values set
        if ( $type eq 'checkbox' ) {
            do { $_->click if $_->get_selected() }
                foreach @inputs;
        }

        if ( $type =~ /^(?:radio|checkbox)$/ ) {
            my @values = ( ref $value eq 'ARRAY' ) ? (@$value) : ($value);

            # foreach value, find an input with that value and check it
            foreach my $val (@values) {
                if ( my $input = $self->find_element(qq|input[name="$field"][value="$val"]|) ) {

                    # click the input, unless it is already selected
                    $input->click unless $input->get_selected();
                }
            }
        }
        elsif ( $type eq 'select-one' ) {

            # we must find the option within this select with the given value, then click it.  But for some reason
            # (at least when using chromedriver) find_element starting with the 'select' doesn't work, so we create
            # a css selector that starts from the top.
            $self->click_element(qq|select[name="$field"] option[value="$value"]|);

        }
        elsif ( @inputs == 1 ) {

            # clear the element and then type our value into the element, as long as we found only one
            $inputs[0]->clear();
            $inputs[0]->send_keys($value);
        }
    }
}

#==
# get_field_values
#
# Get field values for all inputs on the current page.
#
# @return {hashref} a set of field $name => $value pairs.  Fields with no values are returned as having
#   an empty string for the value.  Also note that checkbox fields are always returned as an aref of values,
#   or a potentially empty aref if nothing is checked.
#==
sub get_field_values {
    my $self = shift;

    my @inputs = $self->find_elements( using => 'css selector', value => 'input,select,textarea' );

    # arrange by name
    my %inputs_by_name = ();
    foreach my $input (@inputs) {
        my $name = $input->get_attribute('name');
        next if not length($name);
        push @{ $inputs_by_name{$name} }, $input;
    }

    my %field_val = ();
    while ( my ( $field_name, $input_aref ) = each %inputs_by_name ) {
        $field_val{$field_name} = $self->_get_value_for_inputs(@$input_aref);
    }

    return \%field_val;
}

#==
# get_field_value
#
# Return the value for an input field with the given name, if any.  If the field is not found, the return
# is undef.  If the field is found but empty or an unchecked or unselected radio button or pulldown, we return
# an empty string.  For checkbox fields we always return an aref, potentially empty if nothing is checked.
#==
sub get_field_value {
    my ( $self, $field_name ) = @_;

    my @inputs = $self->find_elements( using => 'css selector', value => qq|input[name="$field_name"]| );
    return $self->_get_value_for_inputs(@inputs);
}

#==
# _get_value_for_inputs
#
# Takes an array of inputs expected to be for the same field (e.g., a group a radio button inputs), and returns
# the value for the field.
#==
sub _get_value_for_inputs {
    my ( $self, @inputs ) = @_;

    return if not @inputs;

    my $val;
    my $type = $inputs[0]->get_attribute('type');
    if ( $type eq 'radio' ) {
        my ($selected_input) = grep { $_->get_selected } @inputs;
        $val = $selected_input->get_attribute('value');
    }
    elsif ( $type eq 'checkbox' ) {
        my @selected_vals = map { $_->get_attribute('value') } grep { $_->get_selected } @inputs;
        $val = \@selected_vals;
    }
    else {
        my @vals = map { $_->get_attribute('value') } @inputs;

        # normally we'll only have one value, but it is possible to have more than one input with the same name for
        # text fields or hidden fields.  If so return an aref ref.
        $val = ( @vals > 1 ) ? \@vals : $vals[0];
    }

    return $val;
}

__PACKAGE__->meta->make_immutable;

1;
