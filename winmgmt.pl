# 
# winmgmt.pl - tools to manage windows in gwillen's preferred fashion
#
# Currently provides the following commands:
#
# ssave:
# - adds all joined channels to the saved channels list with /channel add
# - does /layout save to save all their window numbers
# - does /save to commit your config
#
# cleanup:
# - destroys all windows with no contents
#
# clearhilight:
# - dehilights all windows
#
# Glenn Willen (gwillen@nerdnet.org)

use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 

$VERSION = "0.01";
%IRSSI = (
    authors     => "Glenn Willen",
    contact     => "gwillen\@nerdnet.org",
    name        => "winmgmt",
    description => "Tools to manage windows in gwillen's preferred fashion",
    license     => "Public Domain",
    url         => "http://irssi.org/",
    changed     => "Tue Feb 8 00:00:00 EST 2011"
);

sub cmd_clearhilight {
  my ($data, $server, $witem) = @_;
  if ($data ne "") {
    Irssi::print("No argument permitted to clearhilight. (Usage: run without arguments to clear all hilights.)");
    return;
  }
  my $saved = Irssi::active_win()->{refnum};
  my @wins = Irssi::windows();
  foreach my $win (@wins) {
    if (!exists $win->{refnum}) {
      print "MISSING REFNUM";
      next;
    }
    if ($win->{data_level}) {
      Irssi::command("win $win->{refnum}");
    }
  }
  Irssi::command("win $saved");
}

sub cmd_cleanup {
  my ($data, $server, $witem) = @_;
  if ($data ne "") {
    Irssi::print("No argument permitted to cleanup. (Usage: run without arguments to destroy all empty windows.)");
    return;
  }

  print "Cleaning up empty windows...";
  my @wins = Irssi::windows();
  foreach my $win (@wins) {
    if (!exists $win->{refnum}) {
      print "MISSING REFNUM?!";
      next;
    }

    if (!$win->{name} && !exists($win->{active})) {
      print "Destroying window $win->{refnum}";
      $win->destroy();
    }
  }
  print "Done.";
}

sub cmd_ssave {
  my ($data, $server, $witem) = @_;
  if ($data ne "") {
    Irssi::print("No argument permitted to ssave. (Usage: run without arguments to add all joined channels to the list of saved channels, and /layout save, and /save.)");
    return;
  }

  print "Saving servers...";
  my @servers = Irssi::servers();
  if (scalar @servers == 0) {
     print "Something's wrong; no servers! Not saving.";
     return;
  }
  foreach my $server (@servers) {
    my $net = "";
    if ($server->{'chatnet'}) {
      $net = $server->{'chatnet'};
    } elsif ($server->{'tag'}) {
      $net = $server->{'tag'};
    } else {
      $net = $server->{'address'};
      # But really, don't do that. I don't think this can even happen.
    }
    Irssi::command("network add $net");
    Irssi::command("server add -auto -network $net $server->{address} $server->{port}");
  }

  print "Saving channels...";
  my @chans = Irssi::channels();
  if (scalar @chans == 0) {
    print "Something's wrong; no channels! Not saving.";
    return;
  }
  foreach my $chan (@chans) {
    my $net = "";
    if ($chan->{'server'}->{'chatnet'}) {
      $net = $chan->{'server'}->{'chatnet'};
    } elsif ($chan->{'server'}->{'tag'}) {
      $net = $chan->{'server'}->{'tag'};
    } else {
      $net = $chan->{'server'}->{'address'};
      # Same caveat as above.
    }
    Irssi::command("channel add -auto $chan->{name} $net $chan->{key}");
  }

  Irssi::command("layout save");
  Irssi::command("save");
}

Irssi::command_bind('test', 'cmd_test');
Irssi::command_bind('clearhilight', 'cmd_clearhilight');
Irssi::command_bind('cleanup', 'cmd_cleanup');
Irssi::command_bind('ssave', 'cmd_ssave');

# vim:set ts=4 sw=4 et:
