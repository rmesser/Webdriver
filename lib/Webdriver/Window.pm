#==
# Webdriver::Window
#
# Each instance of this class represents an window, as defined in the Webdriver spec.  We can send various
# window-level commands to an instance of this class.
#==
package Webdriver::Window;
use Moose;
use MooseX::FollowPBP;
use namespace::autoclean;

extends 'Webdriver::Component';

has '+agent' => (
    handles => {

        # Change the size of the specified window.
        set_size => [ 'get_request_data', 'POST', 'size' ],

        # Get the size of the specified window.
        get_size => [ 'get_request_data', 'GET', 'size' ],

        # Change the position of the specified window.
        set_position => [ 'get_request_data', 'POST', 'position' ],

        # Get the position of the specified window.
        get_position => [ 'get_request_data', 'GET', 'position' ],

        # Maximize the specified window if not already maximized.
        maximize => [ 'get_request_data', 'POST', 'maximize' ],
    }
);

__PACKAGE__->meta->make_immutable;

1;
