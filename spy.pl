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

$timeout = 10;
$min_send_interval = 5;

$buf = "";
$maxtimer = undef;
$mintimer = undef;
$lockout = 0;

@data = ();

sub trim($)
{
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub find_server_by_network($) {
  my ($net) = @_;

  foreach my $s (Irssi::servers()) {
    if (lc($s->{'chatnet'}) eq lc($net)) {
      return $s;
    }
  }
  return undef;
}

sub cmd_debug {
  my ($data, $server, $witem) = @_;
  print(eval($data));
}

sub allow_send() {
  $lockout = 0;
  # We should really check if we missed a send, and do it now if we did. I
  # _think_ the other timer should always catch us, but I'm not certain.
}

sub flush_buf() {
  if ($lockout) {
    return;  # Toon soon since last send -- we're locked out.
  }
  my $send = substr($buf, 0, $linemax);
  $buf = substr($buf, $linemax);
  my $copynetwork = trim(Irssi::settings_get_str('copy_network'));
  my $copytarget = trim(Irssi::settings_get_str('copy_to_user'));
  return if $copytarget eq "";
  $server = find_server_by_network($copynetwork);
  $server->command("MSG $copytarget $hdr$send");
  $lockout = 1;
  $mintimer = Irssi::timeout_add_once($min_send_interval * 1000, \&allow_send, undef);
  if ($buf ne "") {
    # Still text to send; restart the clock.
    $maxtimer = Irssi::timeout_add_once($timeout * 1000, \&flush_buf, undef);
  }
}

sub copy_msg($) {
  my ($copy) = @_;
  $copy = length($copy) . ":$copy;";
  if ($buf eq "") {
    # Start the clock.
    $maxtimer = Irssi::timeout_add_once($timeout * 1000, \&flush_buf, undef);
  }
  $buf .= $copy;
  if (length $buf >= $linemax) {
    flush_buf();
  }
}

sub print_text {
  my ($textdest, $text, $stripped) = @_;
  my $copychannel = trim(Irssi::settings_get_str('copy_channel'));
  return if $copychannel eq "";
  if ($textdest->{'target'} eq $copychannel) {
    copy_msg($stripped);
  }
  @data = @_;
}

sub message_own_private {
  my ($server, $msg, $target, $orig_target) = @_;
  if (substr($msg, 0, length($hdr)) eq $hdr) {
    # We're sending an encoded message.
    Irssi::signal_stop();
  }
}


$recv_buf = {};

sub message_private {
  my ($server, $msg, $nick, $address) = @_;
  if (substr($msg, 0, length($hdr)) eq $hdr) {
    # It's an encoded message.
    Irssi::signal_stop();
    $msg = substr($msg, length($hdr));
    $recv_buf->{$nick} = "" if !defined $recv_buf->{$nick};
    $recv_buf->{$nick} .= $msg;
    my $window = Irssi::window_find_name("spy-$nick");
    if (!$window) {
      my $saved = Irssi::active_win()->{refnum};
      Irssi::command("window new hide");
      Irssi::command("window name spy-$nick");
      $window = Irssi::window_find_name("spy-$nick");
      Irssi::command("window $saved");
    }
    while ($recv_buf->{$nick} and $recv_buf->{$nick} !~ /^[0-9]+:/) {
      print "FRAMING ERROR: buffer starts with junk: $recv_buf->{$nick}";
      print "Flushing buffer to next semicolon";
      my ($flush, $keep) = split(";", $recv_buf->{$nick}, 2);
      $window->print("<FRAMING ERROR>$flush", MSGLEVEL_PUBLIC);
      $recv_buf->{$nick} = $keep;
    }
    my ($len, $rest) = split(":", $recv_buf->{$nick}, 2);
    if (length($rest) < $len+1) {
      # We don't have a full line yet, don't try to process it. Wait for more.
      return;
    }
    while (defined $rest) {
      my $body = substr($rest, 0, $len);
      $window->print($body, MSGLEVEL_PUBLIC);
      my $semi = substr($rest, $len, 1);
      if ($semi ne ";") {
        print "FRAMING ERROR: Missing semicolon after message in buffer";
      }
      $recv_buf->{$nick} = substr($rest, $len+1);
      ($len, $rest) = split(":", $recv_buf->{$nick}, 2);
    }
  }
}

Irssi::command_bind('debug', 'cmd_debug');

Irssi::settings_add_str('spy', 'copy_network', 'Freenode');
Irssi::settings_add_str('spy', 'copy_channel', '');
Irssi::settings_add_str('spy', 'copy_to_user', '');

Irssi::signal_add_last('print text', 'print_text');
Irssi::signal_add_last('message private', 'message_private');
Irssi::signal_add_last('message own_private', 'message_own_private');

# vim:set ts=4 sw=4 et:
