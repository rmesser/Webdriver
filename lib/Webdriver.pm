package Webdriver;

use 5.006;
use strict;
use warnings;

=head1 NAME

Webdriver - A Perl module used to communicate with and send commands to a
WebDriver server, such as selenium or chromedriver.
See http://code.google.com/p/selenium/wiki/JsonWireProtocol.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

See the examples directory for usage.  Here also is a small example usage:

    # This example assumes you have chromedriver running locally, on the
    # default port 9515.  But the same example would work going to a remote
    # selenium server.

    use Webdriver::Server;

    my $wd_server = Webdriver::Server->new( port => 9515 );
    my $browser = $wd_server->get_new_browser();
    $browser->set_url('http://wikipedia.org');
    
    # do a query by simulating type with a return at the end
    $browser->send_keys("testing\n");
    
    # now find the first result and print its text
    my $element = $browser->find_element(
        using => 'css selector',
        value => 'li'
    );
    print $element->get_text;
    
    # or the same thing with more direct method
    print $browser->get_element_text('li');
    
=head1 LICENSE AND COPYRIGHT

Copyright 2013 IntelliSurvey, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Webdriver
