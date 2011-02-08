#!/usr/local/bin/perl

 use IO::Socket;
 use Text::CSV;
 use Text::CSV::Simple;


 use strict;
 use vars qw (@chatvars $portnumber $securitycode $parser $j $a $sock $argnum);

 $parser = Text::CSV::Simple->new;

 @chatvars = $parser->read_file('chat_vars.csv');
 for ($j=0; $j<=$#chatvars; $j++) {
  if (lc($chatvars[$j][0]) eq "portnumber") {
   $portnumber=$chatvars[$j][1];
  } elsif (lc($chatvars[$j][0]) eq "securitycode") {
   $securitycode=$chatvars[$j][1];
  }
 }







 $a='';
 foreach $argnum (0 .. $#ARGV) {
  $a=$a.$ARGV[$argnum]." ";
 }
 $a=trim($a);
 my $sock = new IO::Socket::INET (
                                  PeerAddr => 'localhost',
                                  PeerPort => $portnumber,
                                  Proto => 'tcp',
                                 );
 die "Could not create socket: $!\n" unless $sock;
 print $sock "$a\n";


while (<$sock>) {
	print "$_";
    }


 close($sock);

 sub trim($)
 {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
 }
