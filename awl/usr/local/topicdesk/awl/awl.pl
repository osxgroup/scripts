#!/usr/bin/perl

use warnings;
use strict;
use POSIX qw(setlocale LC_ALL);
use lib 'include';

my $NAME = 'com.topicdesk.awl';
my $VERSION = '0.11';
my $skiprelay = '127\.';
my $logfile	 = '/var/log/mail.log';
my %ids;	# holds postfix queue ids for parsing
my $AWL = 'data/awl.txt';

unless ( -d "data" ) {
    mkdir "data",0777 or die $!;
}

setlocale(LC_ALL, 'C');

sub _send {
  my ($mday,$mon,$year) = (localtime)[3..5];
  my $ymd = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
  my $outfile = "data/mailout_$ymd.log";
#  print("Outgoing: $_[0] $_[1] $_[2]\n");
  open(my $fh, '>>', $outfile) or die "Could not open file '$outfile' $!";
  say $fh "Outgoing: $_[0] $_[1] $_[2]";
  close $fh;
  my $mtime = (stat($AWL))[9];
    if (time - $mtime > 300) {
    system("include/awl_update");
  }

}

# Log handling
my $log_re = qr%
    ^[^\[]+?			# stop parse quick if instance not found
    [ ] postfix/(?:smtp|qmgr) \[ [^ ]+ # postfix instance
    (?: [ ] \[ [^\]]* \] )?	# [ID \d+ mail.info] ?
    [ ] ([a-zA-Z0-9]+):		# queue id
    [ ] (?:
      (r)emoved |
      from=<([^>]+\@[^>]+)> |
      to=<([^>]+\@[^>]+)>, [ ] relay= [^\[,]+ \[ ((?!$skiprelay)[\d.]+) \] [^\(]+ status=sent
    )
%x;

sub _parse_logline {
    return unless $_[0] =~ $log_re;
    if (defined $2) { # removed
        delete $ids{$1};
    } elsif (defined $3) { # from
        $ids{$1} = lc($3);
    } else { # to
        # from, to , relay
        _send($ids{$1}, lc($4), $5) if defined $ids{$1};
    }
}

# pretty exit
$SIG{TERM} = sub { _log('Exiting..'); exit; };

eval { require File::Tail; };
die $@ if $@;

while (1) {
    my $logfile = File::Tail->new(
        name => $logfile,
        maxinterval => 3,
        interval => 3,
        resetafter => 30,
        maxbuf => 524288,
        ignore_nonexistant => 1,
        );
    my $line;
    _parse_logline($line) while (defined($line = $logfile->read));
    _log('Restarting File::Tail? This should not happen?', 'warning');
    sleep(5);
}

1;

