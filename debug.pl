# 
# debug.pl - run arbitrary perl code in irssi
#
# This is very dangerous! You idiot! Why are you running this? ;-)
#
# Glenn Willen (gwillen@nerdnet.org)

use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 

$VERSION = "0.01";
%IRSSI = (
    authors     => "Glenn Willen",
    contact     => "gwillen\@nerdnet.org",
    name        => "debug",
    description => "Run arbitrary perl code in irssi",
    license     => "Public Domain",
    url         => "http://irssi.org/",
    changed     => "Fri May 11 00:00:00 EST 2012"
);

sub cmd_debug {
  my ($data, $server, $witem) = @_;
  print(eval($data));
}

Irssi::command_bind('debug', 'cmd_debug');

# vim:set ts=4 sw=4 et:
