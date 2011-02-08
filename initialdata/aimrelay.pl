#!/usr/local/bin/perl




# @INC=();
# push @INC,"." ;
# no lib;
# use lib './liveanswers/perl5';
# use lib './liveanswers/perl5/5.8.8';
# use lib './liveanswers/perl5/5.8.8/mach';
# use lib './liveanswers/site_perl';
# use lib './liveanswers/site_perl/5.8.8';
# use lib './liveanswers/site_perl/5.8.8/mach';


 use Net::OSCAR qw(:standard);
 use IO::Socket;
 use Text::CSV;
 use Text::CSV::Simple;
 use Data::Dumper 'Dumper';
 use HTML::Strip;
 use POSIX qw(setsid);

 use strict;
 use vars qw ($parser $debug $pidfile @webbots $j @oscar @connecting @connected @commit_buddylist
              @csrlist @list @bridges $ready $k $b0 $b1 $b2 $i $j $l $e $a @bridges $c $d @c $dirty
              $bits1 $rc $rout1 $wout1 $eout1 $inbridge @c $inoscar $p $aa $q %touch @chatvars
              $portnumber $securitycode $connectedtomsg $temp %webusers $secure $loginurl);



 $parser = Text::CSV::Simple->new;

 chdir "/usr/home/clearimageonline/cgi/private/livetalk/";


 sub sendim {
  my ($oscar,$t,$m) = @_;
  $oscar->send_im ($t, $m);
 }

 sub whois {
  my ($t) = @_;
  if ($webusers{$t} ne "") {
   return $webusers{$t}."(".$t.")";
  } else {
   return $t;
  }
 }




 sub globals {
  # Check if this is the first time, if not destroy all OSCAR objects
  if (@webbots) {
   for ($j=0; $j<=$#webbots; $j++) {
    if ($oscar[$j]) {
     $oscar[$j]->DESTROY;
     $connecting[$j]='FALSE';
     $connected[$j]='FALSE';
     $commit_buddylist[$j]='FALSE';
    }
   }
  }

  @webbots  = $parser->read_file('webbots.csv');
  @csrlist  = $parser->read_file('csrlist.csv');
  @chatvars = $parser->read_file('chat_vars.csv');


  open(CN,"webusers.csv");
  while (<CN>) {
   chomp;
   ($b0, $b1) = split(/\,/, $_, 2);
   $b0 =~ tr/"//d;
   $b1 =~ tr/"//d;
   $webusers{trim($b0)}=trim($b1);
  }
  close(CN);



  for ($j=0; $j<=$#chatvars; $j++) {
   if (lc($chatvars[$j][0]) eq "portnumber") {
    $portnumber=$chatvars[$j][1];
   } elsif (lc($chatvars[$j][0]) eq "securitycode") {
    $securitycode=$chatvars[$j][1];
   } elsif (lc($chatvars[$j][0]) eq "connectedtomsg") {
    $connectedtomsg=$chatvars[$j][1];
   } elsif (lc($chatvars[$j][0]) eq "loginurl") {
    $loginurl=$chatvars[$j][1];
   }
  }



  @list;
  $bridges[0][0]="ERROR";

  # Set some globals
  $ready=0;
  for ($j=0; $j<=$#webbots; $j++) {
   $connected[$j]='FALSE';
   $connecting[$j]='FALSE';
   $commit_buddylist[$j]='FALSE';
   $list[$j][0]=$webbots[$j][0];
  }
  for ($k=0; $k<=$#csrlist; $k++) {
   $list[$j+$k][0]=$csrlist[$k][0];
  }
 }


globals;


sub im_error {
 my($oscar, $connection, $imerror, $description, $fatal) = @_;
 my $dirty="FALSE";
 print "IM_ERROR----BEGIN----\r\n";
 for ($j=0; $j<=$#list; $j++) {
  if (lc($oscar->{screenname}) eq lc($list[$j][0])) {
   if ($imerror==0 and $fatal==1) {
    # Lost connection to BOS or You've been connecting too frequently.
    $oscar[$j]->DESTROY;
    $connecting[$j]='FALSE';
    $connected[$j]='FALSE';
    $commit_buddylist[$j]='FALSE';
   }
   $dirty="TRUE";
   print "$imerror:$fatal, ($list[$j][0])$description\r\n";
  }
 }
 if ($dirty eq "FALSE") {
  print "IM_ERROR----BEGIN OSCAR----\r\n";
  print Dumper $oscar;
  print "----END OSCAR----\r\n";
  print "IM_ERROR----BEGIN CONNECTION----\r\n";
  print Dumper $connection;
  print "----END CONNECTION----\r\n";
  print "$imerror:$fatal, $description\r\n";
 }
 print "IM_ERROR----END----\r\n";
}






sub im_in {

 # Need to rework to handle multiple stacked requests from BROADCAST

 my($oscar, $sender, $message, $is_away) = @_;
 my $hs = HTML::Strip->new();
 my $a, $b0, $b1, $b2, $j, $i, $k, $c, $d, $e;


 print "IM_IN----BEGIN----\r\n";
 print "$sender:$is_away:$message\r\n";
 print "IM_IN----END----\r\n";


 # Strip html if it exists..
 $a = $hs->parse($message);
 $hs->eof;
 $message =~ s/<html>//g;
 $message =~ s/<\/html>//g;
 $message =~ s/href/target="LiveAnswers" href/g;
 $message =~ tr/  / /s;
 $a =~ tr/  / /s;
 $a=trim($a);
 ($b0, $b1, $b2) = split(/\s+/, $a, 3);
 if ($is_away==0) {
 for ($j=0; $j<=$#bridges; $j++) {
  if (lc($oscar->{screenname}) eq lc($bridges[$j][1]) and lc($sender) eq lc($bridges[$j][0])) {



   # Begin handle server commands
   if (lc($b0) eq lc("SET") or lc($b0) eq lc("GET") or lc($b0) eq lc("LOGIN")){
    if (lc($b0) eq lc("SET")) {
     if ($b1 ne "") {
      $webusers{$b1}=$b2;
      open (CN, '>webusers.csv');
      while( my ($k, $v) = each %webusers ) {
       print CN '"'.trim($k).'","'.trim($v).'"'."\r\n";
      }
      close (CN);
      sendim($oscar,$sender,'/me SET--> "'.$b1.'"="'.$b2.'"');
     }
    }

    if (lc($b0) eq lc("GET")) {
     if ($b1 ne "") {
      sendim($oscar,$sender,'/me GET--> "'.$b1.'"="'.$webusers{$b1}.'"');
     }
    }

    if (lc($b0) eq lc("LOGIN")) {
     sendim($oscar,$sender,$loginurl);
    }



    $b0="";
    $b1="";
    $b2="";
    $a="";
    $message="";
   }
   # End handle server commands



   $bridges[$j][8]="";
   if ($a eq "BREAK") {$bridges[$j][3]="";}
   if ($bridges[$j][3] eq '') {
    # Ok we are not connected see if it is an accept message
    $d=trim($bridges[$j][4]);
    if ($d eq '') {
     # No pending conections let the user know.
     $bridges[$j][4]=trim($bridges[$j][4]);
     my $dirty="FALSE";
     for ($i=0; $i<=$#bridges; $i++) {
      if ($bridges[$i][3] eq '') {
      } else {
       if ($dirty eq "FALSE") {$dirty='';}
       $dirty=$dirty."/me $bridges[$i][0] is handling request ".whois($bridges[$i][3]).".\r\n";
      }
     }
     if ($dirty eq "FALSE") {
#     $oscar->send_im ($sender, "No pending Requests.");
      sendim($oscar,$sender, "/me has no requests pending.");
     } elsif ($dirty ne "TRUE") {
#     $oscar->send_im ($sender,$dirty);
      sendim($oscar,$sender,$dirty);
     }
    } else {
     # Appears like we have some pending connections
     # Ok now we make the connection, then send the message.
     ($c, $d) = split(/\s+/, $bridges[$j][4],2);
     $bridges[$j][3]=$c;
     $bridges[$j][4]=$d;
     # send this broadcast to the same CSR in other open BOT channels
     if ($bridges[$j][4] ne "") {
      for ($i=0; $i<=$#bridges; $i++) {
       # look for the same csr, different bot with no active connection, but the bot needs to be connected
       if ($bridges[$j][0] eq $bridges[$i][0] and $i ne $j and $bridges[$i][3] eq "" and $oscar[$i] and $connected[$i] eq "TRUE") {
        $e="";
        $bridges[$i][4]=$bridges[$i][4]." ".$bridges[$j][4];
        $bridges[$i][4]=trim($bridges[$i][4]);
        $bridges[$j][4]="";
        @c = split(/\s+/, $bridges[$i][4]);
# Make sure we don't already have them in here <<>>
        $dirty="FALSE";
        for ($d=0; $d<=$#c; $d++) {
         $_=$e;
         if (/$c[$d]/) {} else {
          $dirty="TRUE";
          $e=$e." ".$c[$d];
         }
        }
        $bridges[$i][4]=trim($e);
        $l=$i;
       }
      }
     }
     # Loop through and clear other requests.
     for ($k=0; $k<=$#bridges; $k++) {
      if ($k ne $j) {
       @c = split(/\s+/, $bridges[$k][4]);
       $e="";
       for ($d=0; $d<=$#c; $d++) {
        if ($bridges[$j][3] eq $c[$d]) {} else {$e=$e." ".$c[$d];}
       }
       $bridges[$k][4]=trim($e);
      }
     }
     if ($dirty eq "TRUE" and $bridges[$l][3] eq "") {
#     $oscar[$l]->send_im ($bridges[$l][0], "REQUEST(S):".$bridges[$l][4]."<br>\r\n---");
      sendim($oscar[$l],$bridges[$l][0], "/me REQUEST(S):".whois($bridges[$l][4]));
     }
     if (lc($b0) eq lc("ACCEPT") or lc($b0) eq lc("BREAK") or lc($b0) eq lc("A") or lc($b0) eq lc(".")) {
#     $oscar->send_im ($sender, "CONNECTED: $bridges[$j][3]");
      sendim($oscar,$sender,"/me has connected you to ".whois($bridges[$j][3]));          
     } else {
      if (open(outfile, ">>chats/comments$bridges[$j][3].txt")) {



       if (lc($b0) eq lc("/ME")) {
       $a =~ s/\/me//g;
        print outfile '<div class="userinfo '.$bridges[$j][0].'">'.$a.'</div><snd></snd>',"\r\n";
       } else {
        print outfile '<div class="reptext '.$bridges[$j][0].'">'.$message.'</div><snd></snd>',"\r\n";
       }
       close(outfile);







      } else {
#      $oscar->send_im ($sender, "DELIVERY FAILURE ON CONNECT $bridges[$j][3]");          
       sendim($oscar,$sender,"/me can't connect (delivery failure) to ".whois($bridges[$j][3]));          
      }
     }
    }
   } else {
    # Already connected, so we will send the message to the assigned channel, only if $is_away isn't set
    # Already connected, so we will send the message to the assigned channel, only if $is_away isn't set
    if ($is_away==0 and $message ne "") {
     if (open(outfile, ">>chats/comments$bridges[$j][3].txt")) {
      $message =~ s/\n/<br>/g;
      $message =~ s/\r/<br>/g;





      if (lc($b0) eq lc("/ME")) {
       $a =~ s/\/me//g;
       print outfile '<div class="userinfo '.$bridges[$j][0].'">'.$a.'</div><snd></snd>',"\r\n";
      } else {
       print outfile '<div class="reptext '.$bridges[$j][0].'">'.$message.'</div><snd></snd>',"\r\n";
      }
      close(outfile);







     } else {
      print "ERROR: Can't print to file (chats/comments$bridges[$j][3].txt)\r\n";
#     $oscar->send_im ($sender, "DELIVERY FAILURE CAN'T OPEN chats/comments$bridges[$j][3].txt");
      sendim($oscar,$sender,"/me can't open chats/comments$bridges[$j][3].txt");
     }
    } else {
     # Do nothing, got an autoresponse, or an empty message
    }
   }
  }
 }
 } else {
  print "BROADCAST WAS AN AUTOREPLY\r\n";
 }
}


sub typing_status {
 my($oscar, $screenname, $stat) =@_;
 for ($j=0; $j<=$#bridges; $j++) {
  if (lc($screenname) eq lc($bridges[$j][0]) and lc($oscar->{screenname}) eq lc($bridges[$j][1])) {
   $bridges[$j][8]=$stat;
  }
 }
# print "TYPING_STATUS: $screenname, $stat\r\n";
}




sub buddy_info {
 my($oscar, $screenname, $buddydata) =@_;
 print "BUDDY_INFO: $screenname, $buddydata\r\n";
}




sub signon_done {
 my($oscar)=@_;
 $oscar->set_extended_status("Clear Image Online Web Chat Relay");
 for ($j=0; $j<=$#webbots; $j++) {
  if (lc($oscar->{screenname}) eq lc($webbots[$j][0])) {
   print "Connection...".$oscar->{screenname}."\r\n";
   $connected[$j]='TRUE';
  }
 }
 @bridges = bridge();
}

sub buddylist_done {
 my($oscar)=@_;
 for ($j=0; $j<=$#list; $j++) {
  if ($oscar->{screenname} eq $list[$j][0]) {
   print "Commit Buddy List...".$oscar->{screenname}."\r\n";
   $commit_buddylist[$j]="FALSE";
  }
 }
}



sub buddylist_error {
 my($oscar)=@_;
 for ($j=0; $j<=$#list; $j++) {
  if (lc($oscar->{screenname}) eq lc($list[$j][0])) {
   print "Commit Buddy List...".$oscar->{screenname}."\r\n";
   $commit_buddylist[$j]="FALSE";
  }
 }
}





 # BEGIN Start a server to accept commands
 if ($securitycode eq "") { die "can't setup server $portnumber until a security code is added."; }
 my $server = IO::Socket::INET->new( Proto => 'tcp', LocalPort => $portnumber, LocalHost => 'localhost' , Listen => 1, Reuse => 1); 
 die "can't setup server $portnumber, Possibly already running" unless $server; 
 print "[Server $0 is running on port $portnumber]\r\n"; 
 vec($bits1,fileno($server),1)=1;
 # END Start a server to accept commands

 # BEGIN infinite loop to watch for incoming connections and also handle OSCAR


 # daemonize the program
 &daemonize;

 while(1) {
  # BEGIN wait for commands from our client
  $rc=select($rout1=$bits1,$wout1=$bits1,$eout1=$bits1,0.5); # poll
  if ($rc) {
#  print ">>";
   my $client = $server->accept();
   $a=<$client>;
   $a=trim($a);
   ($secure, $b0, $b1, $b2) = split(/\s+/, $a, 4);
   if ($secure eq $securitycode) {
    $a=trim($b0);
#   print "$a\r\n";
    $client->autoflush(1);
    # command in, now act on it
    # Connect, Disconnect, sendIM etc.





    if ($b0 eq 'CONNECT') {
     # CONNECT webbot
     # Loop through to find webbot, if found disconnect
     for ($j=0; $j<=$#webbots; $j++) {
      if (lc($b1) eq lc($webbots[$j][0])) {
       if ($connecting[$j] eq "TRUE") {
        if ($connected[$j] eq "TRUE") {
         print $client "Connected...$b1\r\n";
        } else {
         print $client "Connecting in process...$b1\r\n";
        }
       } else {
        print $client "Connecting...$b1\r\n";
        $connecting[$j]='TRUE';
        $oscar[$j]=Net::OSCAR->new(capabilities => [qw(extended_status typing_status)]);
        $oscar[$j]->set_callback_im_in(\&im_in);
        $oscar[$j]->set_callback_buddy_info(\&buddy_info);
        $oscar[$j]->set_callback_error(\&im_error);
        $oscar[$j]->set_callback_signon_done(\&signon_done);
        $oscar[$j]->set_callback_buddylist_ok(\&buddylist_done);
        $oscar[$j]->set_callback_buddylist_error(\&buddylist_error);
        $oscar[$j]->set_callback_typing_status(\&typing_status);
        $oscar[$j]->signon(
         screenname => $webbots[$j][0],
         password   => $webbots[$j][1]
        );
       }
      }
     }
    }





    elsif ($b0 eq 'DISCONNECT') {
     # DISCONNECT webbot
     # Loop through to find webbot, if found disconnect
     for ($j=0; $j<=$#webbots; $j++) {
      if (lc($b1) eq lc($webbots[$j][0])) {
       if ($oscar[$j]) {
        $oscar[$j]->DESTROY;
        $connecting[$j]='FALSE';
        $connected[$j]='FALSE';
        print $client "Disconnected\r\n";
       } else {
        print $client "Disconnected\r\n";
       }
      }
     }
    }



    elsif ($b0 eq 'EXIT') {
     # DISCONNECT webbot
     print $client "EXIT\r\n";
     print $client "CLOSE\r\n";
     die "EXIT COMMAND RECIEVED!!";
    }





    elsif ($b0 eq 'BREAK') {
     # BREAK message
     # use sub as others may need access to it
     $k=breaksession($b0,$b1);
     print "$k\r\n";
    }






    elsif ($b0 eq 'BROADCAST') {
     # BROADCAST message
     # Loop through bridges and send to those who are not already connected
     $touch{$b1}=time();
     @bridges = bridge();
     $inbridge="FALSE";
     $inoscar="FALSE";
     # Avoid double broadcasts by scanning if this has already been connected
     for ($j=0; $j<=$#bridges; $j++) {
      if ($bridges[$j][3] eq $b1) {$inbridge="TRUE"}
     }
     if ($inbridge eq "TRUE") {
      print $client "ERROR: Broadcast already sent and answered\r\n";
     } else {
      for ($j=0; $j<=$#bridges; $j++) {
       if ($bridges[$j][2] eq "AVAILABLE" and $bridges[$j][3] eq '') {
        # Ok found an available bridge now send it via the found webbot
        $inbridge="TRUE";
        $i=$bridges[$j][5];
        if ($oscar[$i] && $connected[$i] eq "TRUE") {
         # Only send to CSR once, check inoscar to see if we have been here before
#  Commented out temporarily
         if ($inoscar ne $bridges[$j][0]) {
#         $oscar[$i]->send_im ($bridges[$j][0], "REQUEST:".$b1."\r\n".$b2);
          sendim($oscar[$i],$bridges[$j][0], "/me ".$b2." requests connection to ".whois($b1));
          # Only add to pending if not there already
          $_=$bridges[$j][4];
          if (/$b1/) {} else {
           $bridges[$j][4]=trim($bridges[$j][4]." ".$b1);
          }
          print $client "SENTVIA $bridges[$j][0] $bridges[$j][1]\r\n";
         }
         $inoscar=$bridges[$j][0];
        } else {
         print $client "ERROR: Oscar connection not found or disconnected\r\n";
        }
        if ($inoscar eq "FALSE") {
         print $client "ERROR: Found bridge, couldn't find webbot, possibly need to reload bridges\r\n";
        }
       } else {
        # NOT AVAILABLE or already chatting
       }
      }
      if ($inbridge eq "FALSE") {
       print "ERROR: No Available bridges available to broadcast to ($b1)\r\n";
       print $client "ERROR: No BRIDGE available (all busy)\r\n";
      }
     }
    }




    elsif ($b0 eq 'SEND') {
     # SEND messagepath message
     # First loop through bridges to find who is handling this message id
     $inbridge="FALSE";
     $inoscar="FALSE";
     for ($j=0; $j<=$#bridges; $j++) {
      if (lc($bridges[$j][3]) eq lc($b1)) {
       # Ok we found who is handling this message, now we need to look up the oscar index
       $inbridge="TRUE";
       $inoscar="FALSE";
       $i=$bridges[$j][5];
       if ($oscar[$i] && $connected[$i] eq "TRUE") {
        $inoscar="TRUE";
#       $oscar[$i]->send_im ($bridges[$j][0], $b2);
        sendim($oscar[$i],$bridges[$j][0],$b2);
        print $client "SENTVIA $bridges[$j][0] $bridges[$j][1]\r\n";
       } else {
        print $client "ERROR: Oscar connection not found or disconnected\r\n";
       }
       if ($inoscar eq "FALSE") {
        print $client "ERROR: Found bridge, couldn't find webbot, possibly need to reload bridges\r\n";
       }
      }
     }
     if ($inbridge eq "FALSE") {
      print $client "ERROR: Path not found\r\n";
     }
    }








    elsif ($b0 eq 'IMSEND') {
     # SEND messagepath message
     # First loop through bridges to find who is handling this message id
     $inoscar="FALSE";
     for ($i=0; $i<=$#webbots; $i++) {
      if ($oscar[$i] && $connected[$i] eq "TRUE" && $inoscar eq "FALSE") {
       $inoscar="TRUE";
#      $oscar[$i]->send_im ($b1, $b2);
       sendim($oscar[$i],$b1,$b2);
       print $client "IMSEND: Sent\r\n";
      }
     }
     if ($inoscar eq "FALSE") {
      print $client "IMSEND: Not sent no available channel to send through\r\n";
     }
    }








    elsif ($a eq 'RELOAD') {
     $dirty="FALSE";
     for ($j=0; $j<=$#bridges; $j++) {
      if ($bridges[$j][3] ne "" or $bridges[$j][4] ne "") {$dirty="TRUE";}
     }
     for ($j=0; $j<=$#webbots; $j++) {
      if ($oscar[$j] and ($connected[$j] eq "TRUE" or $connecting[$j] eq "TRUE")) {$dirty="TRUE";}
     }
     if ($dirty eq "TRUE") {
      print $client "ERROR: can't reload with active or pending connections\r\n";
     } else {
      globals;
      print $client "RELOAD\r\n";
     }
    }






    elsif ($b0 eq 'STATUS') {
     for ($j=0; $j<=$#webbots; $j++) {
      print $client "$webbots[$j][0] $connected[$j] $connecting[$j] $commit_buddylist[$j]\r\n";
     }
    }



    elsif ($a eq 'LIST') {
     print $client table(@list);
    }
    elsif ($a eq 'WEBBOTS') {
     print $client table(@webbots);
    }
    elsif ($a eq 'CSRLIST') {
     print $client table(@csrlist);
    }
    elsif ($b0 eq 'WEBUSERS') {
     if ($b1 ne "") {
      $webusers{$b1}=$b2;
     }
     while( my ($k, $v) = each %webusers ) {
      print $client '"'.$k.'", "'.$v.'"'."\r\n";
     }
    }
    elsif ($b0 eq 'BRIDGES') {
     if ($b1 ne "") {$touch{$b1}=time();}
     @bridges = bridge();
     print $client table(@bridges);
    }
    elsif ($a eq 'READY') {
     @bridges = bridge();
     print $client "$ready\r\n";
    }
    print $client "CLOSE\r\n";


 
   } else {
    print $client "ERROR: Mismatched Security Code:\r\n";
    print $client "CLOSE\r\n";
   }
  }
  # END wait for commands from our client


  # Grab the time
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  my $theTime = "$months[$month] $dayOfMonth, $year at $hour:$minute";
  # Disconnected - Jun 21, 07 at 1:23 PM


  # Loop through bridges to kill any sessions that haven't been touched for 60 seconds
  for ($j=0; $j<=$#bridges; $j++) {
   # First check the active slot
   $b0="";
   if ($bridges[$j][3] ne "") {
    if ($touch{$bridges[$j][3]}+15<time()) {
     if (open(outfile, ">>chats/comments$bridges[$j][3].txt")) {
      print outfile '<div class="userinfo">Disconnected - '.$theTime.'</div><snd></snd>',"\r\n";
      close(outfile);
     }
     $b0="BREAK";
     $b1=$bridges[$j][3];
     $k=breaksession($b0,$b1);
#    print "$k\r\n";
    }
   }
   # Now check Pending Slots
   $e="";
   @c = split(/\s+/, $bridges[$j][4]);
   for ($d=0; $d<=$#c; $d++) {
    if ($touch{$c[$d]}+15<time()) {
#    Disable pending request disconnect notice to web user, CSR will still get them
#    if (open(outfile, ">>chats/comments$c[$d].txt")) {
#     print outfile '<div class="userinfo">Disconnected - '.$theTime.'</div><snd></snd>',"\r\n";
#     close(outfile);
#    }
     $b0="BREAK";
     $b1=$c[$d];
     $k=breaksession($b0,$b1);
#    print "$k\r\n";
    } else {
     $e=$e.$c[$d]." ";
    }
   }
   $bridges[$j][4]=trim($e);
  }



  # BEGIN OSCAR stuff
  for ($j=0; $j<=$#webbots; $j++) {
   if ($connecting[$j] eq 'TRUE') { $oscar[$j]->do_one_loop(); }
  }





  # END OSCAR stuff



 }
 # END infinite loop to watch for incoming connections and also handle OSCAR






 sub trim($)
 {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
 }




sub table {
 my (@list) = @_;
 my $a = "";
 my $j = 0;
 my $k = 0;
 for ($k=0; $k<=$#list; $k++) {
  for ($j=0; $j<=$#{$list[0]}; $j++) {
   $a=$a."\"".$list[$k][$j]."\", ";
  }
  chop($a);
  chop($a);
  $a=$a."\r\n";
 }
 return $a;
}







sub buddyup {
 my $j;
 for ($j=0; $j<=$#webbots; $j++) {
  if ($oscar[$j] && $connected[$j] eq "TRUE") {
   # Ok we have a connection now we can add missing buddies
   my $k = 0;
   my $x = 0;
   my $p = 0;
   my $q = 0;
   my $b;
   my $c;
   my $dirty="FALSE";
   # We add all csr's and bot's to list
   for ($k=0; $k<=$#list; $k++) {
     $p=$oscar[$j]->findbuddy(lc($list[$k][0]));
     if ($p) {
      # found in buddy list do nothing
     } else {
      # not found lets add them
      $p=$oscar[$j]->add_buddy('Clear Image',lc($list[$k][0]));
      $dirty="TRUE";
      print "$p $list[$k][0]   <--Buddy Status (added)\r\n";
     }
   }
   # Commit the list as long as it hasn't been called before.
   if ($commit_buddylist[$j] eq "FALSE" and $dirty eq "TRUE") {
    $oscar[$j]->commit_buddylist();
    $commit_buddylist[$j]="TRUE";
    print "Committing Buddlist...\r\n";
   } else {
#   print "No need to Commit Buddlist...\r\n";
   }
  }
 }
}










sub bridge {
 buddyup;
 my $j;
 my $i;
 my @a;
 my $x=0;
 $ready=0;
 # Loop only lasts till a connection is found, last iteration will create a bridge with no connections (i.e. no connections found)
 for ($j=0; $j<=$#webbots+1; $j++) {
  if (($oscar[$j] and $connected[$j] eq "TRUE") or $j==$#webbots+1) {
   # Ok here we create, monitor our bridge
   for ($k=0; $k<=$#csrlist; $k++) {
    for ($i=0; $i<=$#webbots; $i++) {
     $a[$x][0]=$csrlist[$k][0];
     $a[$x][1]=$webbots[$i][0];
     # Check status of csr $p is the status of the csr
     if ($#webbots+1==$j) {
      $p=0;
     } else {
      $c=$oscar[$j]->buddy($csrlist[$k][0]);
      $p=$c->{online};
      $aa=$c->{extended_status};
      if ($aa eq "Away") {$p=0;}
     }
     # Check status of bot $q is the status of the bot
     if ($connected[$i] eq "TRUE") {$q="1";} else {$q="0";}
     if ($p eq "1" and $q eq "1") {$a[$x][2]="AVAILABLE"; $ready=$ready+1;} else {$a[$x][2]="NOTAVAILABLE";}
     if ($bridges[$x][3]) {$a[$x][3]=$bridges[$x][3];} else {$a[$x][3]='';}
     if ($bridges[$x][4]) {$a[$x][4]=$bridges[$x][4];} else {$a[$x][4]='';}
     $a[$x][5]="$i";
     $a[$x][6]="$p";
     $a[$x][7]="$q";
     if ($bridges[$x][8]) {$a[$x][8]=$bridges[$x][8];} else {$a[$x][8]='';}
     $x=$x+1;
    }
   }
   return @a;
  } # end if oscar
 }  # End For loop
}






sub breaksession {
    my ($b1,$b1) = @_;
    my ($j,$k,$i,$e,$inbridge,$dirty,$rt,$msg,@c);
    $rt="";
    # Loop through bridges and break all "message" connections
    $inbridge="FALSE";
    $msg="";
    for ($j=0; $j<=$#bridges; $j++) {
     if ($bridges[$j][3] eq $b1) {
      $bridges[$j][3]='';
      $inbridge="TRUE";
      $rt=$rt."BREAK $bridges[$j][0]\r\n";
      $i=$bridges[$j][5];
      if ($oscar[$i] && $connected[$i] eq "TRUE") {
       # Ok pick up any other outstanding chats
       $e=$bridges[$j][4];
       for ($k=0; $k<=$#bridges; $k++) {
        if ($bridges[$k][4] ne ""){
         $bridges[$k][4]=trim($bridges[$k][4]);
         @c = split(/\s+/, $bridges[$k][4]);
         for ($d=0; $d<=$#c; $d++) {
          $_=$e;
          if (/$c[$d]/) { } else {
           $e=$e." ".$c[$d];
          }
         }
         $bridges[$j][4]=trim($e);
        }
       }
       if ($bridges[$j][4] eq "") {
#       $oscar[$i]->send_im ($bridges[$j][0], "CLOSED: ".$b1."<br>No Pending Requests..");
        sendim($oscar[$i],$bridges[$j][0],"/me ".whois($b1)." has closed the chat.");
       } else {
#       $oscar[$i]->send_im ($bridges[$j][0], "CLOSED: ".$b1);
#       $oscar[$i]->send_im ($bridges[$j][0], "PENDING:".$bridges[$j][4]."<br>\r\n---");
        sendim($oscar[$i],$bridges[$j][0], "/me ".whois($b1)." has closed the chat. Requests still pending: ".whois($bridges[$j][4]));
       }
      }
     }
    }
    if ($inbridge eq "FALSE") {
     # Ok we didn't find it in the active requests, lets remove it from all pending requests
     $dirty="FALSE";
     for ($j=0; $j<=$#bridges; $j++) {
      $i=$bridges[$j][4];
      $bridges[$j][4]=~s/$b1//;
      $bridges[$j][4]=~s/\s+/\s/g;
      if ($i eq $bridges[$j][4]) {} else {
       $dirty="TRUE";
       $i=$bridges[$j][5];
#      $oscar[$i]->send_im ($bridges[$j][0], "CLOSED: ".$b1);
       sendim($oscar[$i],$bridges[$j][0],"/me ".whois($b1)." chat closed.");
      }
     }
     if ($dirty eq "TRUE") {
      $rt=$rt."BREAK PENDING REQUEST REMOVED\r\n";
     } else {
      $rt=$rt."BREAK NOT FOUND\r\n";
     }
    }
 return $rt;
}




sub daemonize {
# Not sure why this was here????
#   chdir '/'                 or die "Can't chdir to /: $!";
    open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    open STDOUT, '>>aimserver.log' or die "Can't write to aimserver.log: $!";
    open STDERR, '>>aimservererror.log' or die "Can't write to aimservererror.log: $!";
    defined(my $pid = fork)   or die "Can't fork: $!";
    exit if $pid;
    setsid                    or die "Can't start a new session: $!";
    umask 0;
}






