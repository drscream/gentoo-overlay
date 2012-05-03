#!/usr/bin/perl -w
#
# DNS blacklist plugin for Nagios
# Written by Ben Ostrowsky <ostrowb@tblc.org>
#
# Last Modified: 2006-09-07
#
# Usage: ./check_dnsbl -H host -B blacklist [-T target] 
#
# Description:
#
# This plugin will check DNS blacklists to see whether a specified host
# is shunned by mail servers using a specified blacklist.
#
# Output:
#
# check_dnsbl will return:
# 0 (OK)       if the BLACKLIST zone does **NOT** claim to know anything
#                 about the HOST.
# 1 (WARNING)  if the BLACKLIST zone has a record for the HOST,
#                 but it is not TARGET. 
# 2 (CRITICAL) if the BLACKLIST zone identifies the HOST as a specified
#                 TARGET, or if the BLACKLIST zone identifies the HOST
#                 and a TARGET was not specified.
# 3 (UNKNOWN) if something goes wrong.
#
# Examples:
#
# Look up 64.233.163.27 in the SpamCop blacklist:
#   check_dnsbl 64.233.163.27 bl.spamcop.net
#
# Find an IP address for mail.mydom.ain and look it up in
# the SORBS Zombie List (http://www.us.sorbs.net/using.shtml):
#   check_dnsbl mail.mydom.ain dnsbl.sorbs.net 127.0.0.9
#
# Copyright Notice: GNU General Public License
#
# Based on the check_rpc plugin by Nguyen, DeBisschop and Ghosh
# IP-address regex by David Landgren
#  (http://aspn.activestate.com/ASPN/Cookbook/Rx/Recipe/230446)
# Net::DNS sample code by Chris Wilkes <cwilkes-rbl@ladro.com>
#  (http://ladro.com/docs/dns/rblsmtpd.html)
# 


#################### DO A BIT OF HOUSEKEEPING #############################

use strict;
use Net::DNS;
use lib "/usr/lib/nagios/plugins";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use vars qw($PROGNAME $VERSION);

my ($v,$host,$blacklist,$target,$resolved,$reversed);
my ($dns,$query,$queryname,$rr,$timeout,$problem);
my ($needle,$haystack,$element,$addresses,$ipregex);
my ($message,$level);
my ($opt_B,$opt_h,$opt_H,$opt_t,$opt_T,$opt_v,$opt_V);
my (@results,@arecords);

# "Explicitly initialize each variable in use. Otherwise with caching
#  enabled, the plugin will not be recompiled each time, and therefore
#  Perl will not reinitialize all the variables. All old variable
#  values will still be in effect."
# http://nagiosplug.sourceforge.net/developer-guidelines.html#PERLPLUGIN
#
$v=0; # default verbosity level
$host=$blacklist=$target=$resolved=$reversed='';
$dns=$query=$queryname=$rr=$timeout=$problem='';
$needle=$haystack=$element=$addresses=$ipregex='';
$message=$level='';
$opt_B=$opt_h=$opt_H=$opt_t=$opt_T=$opt_v=$opt_V='';
@results=@arecords=();

$PROGNAME = "check_dnsbl";
$VERSION = "1.0";
sub print_help ();
sub print_usage ();
sub kvetch ($);           # Kvetch (verb): To complain annoyingly.
sub in ($$);
sub verbose($$$);

# Regular expression to identify a valid IPv4 address
$ipregex='^(?:1\d?\d?|2(?:[0-4]\d?|[6789]|5[0-5]?)?|[3-9]\d?|0)'
       . '(?:\.(?:1\d?\d?|2(?:[0-4]\d?|[6789]|5[0-5]?)?|[3-9]\d?|0)){3}$';


#################### HANDLE THE COMMAND LINE ##############################

use Getopt::Long;
Getopt::Long::Configure('bundling');
GetOptions(
	"V"   => \$opt_V,   "version"     => \$opt_V,
  "h"   => \$opt_h,   "help"        => \$opt_h,
  "v+"  => \$v,       "verbose+"    => \$v,
  "H=s" => \$opt_H,   "hostname=s"  => \$opt_H,
  "B=s" => \$opt_B,   "blacklist=s" => \$opt_B,
  "T=s" => \$opt_T,   "target=s"    => \$opt_T,
  "t=s" => \$opt_t,   "timeout=s"   => \$opt_t  
);

# -h means display verbose help screen
if ($opt_h) {
	print_help();
	exit $ERRORS{'OK'};
}

# -V means display version number
if ($opt_V) {
  print_revision($PROGNAME,"version $VERSION");
  exit $ERRORS{'OK'};
}

# -H means host name
unless ($opt_H) {
	kvetch("You must specify a host (-H host).");
}
if (! utils::is_hostname($opt_H)) {
	kvetch("$opt_H is not a valid hostname or IP address.");
}

# -B means blacklist
unless ($opt_B) {
	kvetch("You must specify a blacklist (-B blacklist).");
}

# -t means timeout
if ($opt_t =~ /^([0-9]+)$/) {
	$timeout = $1;
	verbose($v, 2, "Timeout is set to $timeout second" . ($timeout>1?"s":"") . ".\n");
}
elsif ($opt_t ne "") {
	kvetch("Timeout (-t) must be an integer number of seconds. Target is -T.");
}
else {
	$timeout = $TIMEOUT;
}

# Set an alarm in case the process times out
$SIG{'ALRM'}= sub {
	kvetch("$PROGNAME took more than $timeout seconds to respond.");
};
alarm($timeout);

# Set up a Net::DNS resolver object
$dns = Net::DNS::Resolver->new;

$host=$opt_H;
$blacklist=$opt_B;
$target=$opt_T;


#################### BEGIN ACTUALLY DOING STUFF ###########################

# Make sure $host is an IP address.  If it's a DNS name, resolve it first.
if ($host =~ /$ipregex/) {
	$resolved = $host;
	verbose($v, 2, "$host is an IP address.  I'm not going to try to resolve it.\n");
}
else {
	$query = $dns->search($host) or kvetch("Couldn't query DNS for \"$host\".");
	foreach $rr ($query->answer) {
		next unless $rr->type eq "A";
		push(@arecords, $rr->address);
	}
	$resolved = $arecords[0];
	if ($#arecords > 0) {
		$addresses = $#arecords + 1;
		verbose($v, 1, "NOTE: $host has $addresses address records.  ");
		verbose($v, 2, "\n\t$host -> " . join("\n\t$host -> ", @arecords) . "\n");
		verbose($v, 1, "I'm only checking $resolved.\n");
	}
	else {
		verbose($v, 1, "Resolved $host to $resolved.\n");
	}
}

# Construct the DNS name to query.
$reversed = join (".", reverse (split (/\./, $resolved)));
$queryname = "$reversed.$blacklist";
verbose($v, 2, "Blacklist address to query: $queryname\n");

# Send the DNS query.
$query = $dns->search($queryname);

# If $query is blank, then the $host is not on the $blacklist.  Hooray!
if (!$query || $query eq "") {
	print "OK: $blacklist does not list $host";
	if ($host ne $resolved) { 
		print " ($resolved)";
	}
	print "\n";
	exit $ERRORS{"OK"};
}

# If the DNS query returned a positive result (one or more IP addresses),
# make a list of the answers we got.
verbose($v, 2, "RESULTS:\n");
foreach $rr ($query->answer) {
	verbose($v, 2, "\t$queryname\t" . $rr->type. "\t" . $rr->address . "\n");
	next unless $rr->type eq "A";
	push (@results, $rr->address);
}

# Are we checking for a specific $target?
if ($target eq "") {
	print "CRITICAL: $blacklist lists $host";
	if ($host ne $resolved) { 
		print " ($resolved)";
	}
	print "!\n";
	exit $ERRORS{"CRITICAL"};
}

# If so, check for $target.
elsif (grep (/$target/, @results) > 0) {
	print "CRITICAL: $blacklist lists $host";
	if ($host ne $resolved) { 
		print " ($resolved)";
	}
	print " as $target";
	print "!\n";
	exit $ERRORS{"CRITICAL"};
}

# If not, return 1 (WARNING).
else {
	print "WARNING: $blacklist lists $host";
	if ($host ne $resolved) { 
		print " ($resolved)";
	}
	print " as " . join(", ", @results);
	print " ...but not as $target";
	print ".\n";
	exit $ERRORS{"WARNING"};
}

# If we get this far, something is wrong.
kvetch("UNKNOWN: $PROGNAME $VERSION didn't work properly. Sorry.");



################ Subroutines ##################################################

# Print help
sub print_help () {
	print_revision ($PROGNAME, "version $VERSION");
	print "Copyright (C) 2006 Ben Ostrowsky <ostrowb\@tblc.org>\n";
	print "\n";
	print "Find out whether an address is on a DNS blacklist\n";
	print "\n";
	print_usage();
	print " <host>          An IP address or domain name whose blacklist status\n";
	print "                 you want to know\n";
	print " <blacklist>     The zone of a DNS blacklist (e.g. bl.spamcop.net)\n";
	print " <target>        The IP address that the DNS blacklist\n";
	print "                 might return (optional)\n";
	print " [-h, --help]    Print this help message and exit\n";
	print " [-V, --version] Print version number and exit\n";
	print " [-v, --verbose] Verbose (repeat for more details)\n";
	print " [--timeout=N]   Set timeout to N seconds (default $TIMEOUT)\n";
	print "     or [-t N]   \n";
	print "\n";
	print "HINTS:\n";
	print "\n";
	print "* If you do not specify a <target>, $PROGNAME will return CRITICAL\n";
	print "  on any match.  Only specify a target if you really want one.\n";
	print "\n";
	print "* If you're just testing this plugin, try using \"-H 127.0.0.2\".\n";
}

# Print basic usage
sub print_usage () {
	print "Usage: \n";
	print "  $PROGNAME -H host -B blacklist [-T target] [-t timeout] [-v] [-v]\n";
	print "  $PROGNAME --help\n";
}

# Does @haystack contain $needle?
# Usage: if (in(\@haystack, $needle)) {}
sub in ($$) {
  $haystack = shift;
  $needle = shift;
  while ( $element = shift @{$haystack} ) {
    if ($needle eq $element) {
      return 1;
    }
  }
  return 0;
}

sub kvetch ($) {
	$problem = shift;
  print "$problem\n";
	print_usage();
  exit $ERRORS{"UNKNOWN"};
}

# Print verbose information. 
# Usage: verbose($v, n, $message);
# Why pass $v every time?
# "Do not use global variables in named subroutines. This is bad practise
#  anyway, but with ePN the compiler will report an error '<global_var>
#  will not stay shared ..'. Values used by subroutines should be passed
#  in the argument list."
# http://nagiosplug.sourceforge.net/developer-guidelines.html#PERLPLUGIN
sub verbose ($$$) { 
	my $verbose = shift;
	$level = shift;
	$message = shift;
	if ($verbose >= $level) {
		print $message;
	}
}
