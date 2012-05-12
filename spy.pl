# 
# spy.pl - Enables two cooperating irssi users to share one user's view of a
# channel.
#
# This is probably a bit evil. Only use your powers for good.
#
# Glenn Willen (gwillen@nerdnet.org)

use Irssi;
use POSIX;
use Data::Dumper;
use vars qw($VERSION %IRSSI); 

$VERSION = "0.01";
%IRSSI = (
    authors     => "Glenn Willen",
    contact     => "gwillen\@nerdnet.org",
    name        => "spy",
    description => "Enables two cooperating irssi users to share one user's view of a channel.",
    license     => "Public Domain",
    url         => "http://irssi.org/",
    changed     => "Fri May 11 00:00:00 EST 2012"
);

$hdr = "xIRCSPYx";
$overhead = length($hdr);
$linemax = 400 - $overhead;

$copynetwork = "Freenode";
$copytarget = "gwillen";
$copychannel = "#cslounge";
$timeout = 10;

$buf = "";
$timer = undef;

@data = ();

sub find_server_by_network($) {
  my ($net) = @_;

  foreach my $s (Irssi::servers()) {
    if ($s->{'chatnet'} eq $net) {
      return $s;
    }
  }
  return undef;
}

sub cmd_debug {
  my ($data, $server, $witem) = @_;
  print(eval($data));
}

sub flush_buf() {
  my $send = substr($buf, 0, $linemax);
  $buf = substr($buf, $linemax);
  $server = find_server_by_network($copynetwork);
  $server->command("MSG $copytarget $hdr$send");
}

sub copy_msg($) {
  my ($copy) = @_;
  $copy = "M" . length($copy) . ":$copy;";
  $buf .= $copy;
  if (length $buf >= $linemax) {
    flush_buf();
  }
  if (length $buf) {
    Irssi::timeout_remove($timer);
    $timer = Irssi::timeout_add_once($timeout * 1000, \&flush_buf, undef);
  }
}

sub message_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  return if $target ne $copychannel;
  $copy = "<$nick> $msg";
  copy_msg($copy);
  @data = @_;
}

sub message_own_public {
  my ($server, $msg, $target) = @_;
  return if $target ne $copychannel;
  $mynick = $server->{'nick'};
  $copy = "<$mynick> $msg";
  copy_msg($copy);
}

sub message_any {
  my ($type, $channel, $nick, $extra1, $extra2) = @_;
  return if $channel ne $copychannel;
  $copy = "$type:<$nick>" . ($extra1 ? ":$extra1" : "") .
                            ($extra2 ? ":$extra2" : "");
  copy_msg($copy);
}

sub message_join {
  my ($server, $channel, $nick, $address) = @_;
  message_any("JOIN", $channel, $nick);
}

sub message_part {
  my ($server, $channel, $nick, $address, $reason) = @_;
  message_any("PART", $channel, $nick, $reason);
}

sub message_quit {
  my ($server, $nick, $address, $reason) = @_;
  # XXX message_any("QUIT", @_);
}

sub message_kick {
  my ($server, $channel, $nick, $kicker, $address, $reason) = @_;
  message_any("KICK", $channel, $nick, $reason, $kicker);
}

sub message_nick {
  my ($server, $nick, $oldnick, $address) = @_;
  # XXX message_any("NICK", @_);
}

sub message_own_nick {
  my ($server, $nick, $oldnick, $address) = @_;
  # XXX message_any("OWN_NICK", @_);
}

sub message_topic {
  my ($server, $channel, $topic, $nick, $address) = @_;
  message_any("TOPIC", $channel, $nick, $topic);
}

Irssi::command_bind('debug', 'cmd_debug');

Irssi::signal_add_last('message public', 'message_public');
Irssi::signal_add_last('message own_public', 'message_own_public');
Irssi::signal_add_last('message join', 'message_join');
Irssi::signal_add_last('message part', 'message_part');
Irssi::signal_add_last('message quit', 'message_quit');
Irssi::signal_add_last('message kick', 'message_kick');
Irssi::signal_add_last('message nick', 'message_nick');
Irssi::signal_add_last('message own_nick', 'message_own_nick');
Irssi::signal_add_last('message topic', 'message_topic');

# vim:set ts=4 sw=4 et:
