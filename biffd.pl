#!/usr/bin/env perl

use v5.12;
use warnings;
use strict;
use Email::MIME;
use MIME::Types;
use File::Temp qw/ tempfile /;

STDOUT->autoflush(1);

say "220 biffd";
my %fields = ();
my $message = "";
my $mail_from;
my $mail_to;
my $in_data;
while (my $line = <>) {
  if ($in_data) {
    if ($line =~ /^\.\s*$/) { say "250"; }
    else { $message .= $line; }
  }
  elsif ($line =~ /^EHLO(\s+.*)?$/i) { say "502 This is not a mail server"; }
  elsif ($line =~ /^HELO(\s+.*)?$/i) { say "250"; }
  elsif ($line =~ /^MAIL FROM:<?(.*?)?>?\s*$/i) { $mail_from = $1; say "250"; }
  elsif ($line =~ /^RCPT TO:<?(.*?)?>?\s*$/i) { $mail_to = $1; say "250"; }
  elsif ($line =~ /^DATA(.*)?$/i) { $in_data = 1; say "354"; }
  elsif ($line =~ /^QUIT(.*)?$/i) { say "221"; last; }
}

# If stdin's fd is a dup of an inet socket, shut it down to end the SMTP session with the client
shutdown(STDIN, 2);

my $email = Email::MIME->new($message);
undef($message);

for ($email->header_names) { $ENV{"MAIL_HEADER_".(uc $_)} = $email->header($_); }
$ENV{"MAIL_FROM"} = $mail_from;
$ENV{"MAIL_TO"} = $mail_to;

my $files_created;
sub create_files {
  return if $files_created;
  $email->walk_parts(sub {
    my ($part) = @_;
    return if $part->parts > 1;
    my $ct = $part->{ct}->{discrete} . "/" . $part->{ct}->{composite};
    my $type = MIME::Types->new->type($ct);
    my $ext = ($type && (($type->extensions)[0])) || 'dat';
    my $base = ($part->header('Content-Disposition') || '') =~ /attachment/ ? 'attachment' : 'body';
    my ($fh, $fn) = tempfile($base . '-XXXX', SUFFIX => ".$ext", TMPDIR => 1, UNLINK => 1);
    print $fh $part->body;
  });

  $files_created = 1;
}

my $config = $ENV{BIFFD_CONFIG} || "biffd.conf";

open(CONF, '<', $config) or die $!;
while (my $line = <CONF>) {
  next if ($line =~ /^#/);
  if ($line =~ /^([A-Za-z0-9_-]+):([^:]*):(.*)$/) {
    my ($key, $match, $cmd) = ($1, $2, $3);
    if (exists $ENV{$key} and ($ENV{$key} || '') eq $match) {
      create_files();
      say STDERR "Running: $cmd";
      say STDERR `$cmd`;
    }
  } else {
    say STDERR "Couldn't parse config line $line";
  }
}
