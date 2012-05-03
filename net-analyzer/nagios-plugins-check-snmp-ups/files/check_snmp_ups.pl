#!/usr/bin/perl -w
############################## check_snmp_ups ###################
# Version : 1.1
# Date : April 17 2009
# Author  : Jürgen Vigna <juergen.vigna@wuerth-phoenix.com>
#
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Changelog : 
#
#################################################################
#
# Help : ./check_snmp_env.pl -h
#

use strict;
use Net::SNMP;
use Getopt::Long;

# Nagios specific

use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);


my @Nagios_state = ("UNKNOWN","OK","WARNING","CRITICAL"); # Nagios states coding

# SNMP Datas

# Net Vision UPS MIB's
my $netvision_base_MIB	=	"1.3.6.1.4.1.4555"; # NetVision UPS base table
my $netvision_alert_table =	"1.3.6.1.4.1.4555.1.1.1.1.6.3";
my @netvision_alert_leaf = (    # 82 elements 0-81 id's are array-index + 1
 'AlarmBatteryBad',
 'AlarmOnBattery',
 'AlarmLowBattery',
 'AlarmDepletedBattery',
 'AlarmTempBad',
 'AlarmInputBad',
 'AlarmOutputBad',
 'AlarmOutputOverload',
 'AlarmOnBypass',
 'AlarmBypassBad',
 'AlarmOutputOffAsRequested',
 'AlarmUpsOffAsRequested',
 'AlarmChargerFailed',
 'AlarmUpsOutputOff',
 'AlarmUpsSystemOff',
 'AlarmFanFailure',
 'AlarmFuseFailure',
 'AlarmGeneralFault',
 'AlarmDiagnosticTestFailed',
 'AlarmCommunicationLost',
 'AlarmAwaitingPower',
 'AlarmShutdownPending',
 'AlarmShutdownImminent',
 'AlarmTestInProgress',
 'AlarmPowerSupplyFault',
 'AlarmAuxMainFail',
 'AlarmManualBypassClose',
 'AlarmShortCircuit',
 'AlarmBatteryChargerFailure',
 'AlarmInverterOverCurrent',
 'AlarmInverterDistorsion',
 'AlarmPrechargeVoltageFail',
 'AlarmBoostTooLow',
 'AlarmBoostTooHigh',
 'AlarmBatteryTooHigh',
 'AlarmImproperCondition',
 'AlarmOverloadTimeout',
 'AlarmControlSystemFailure',
 'AlarmDataCorrupted',
 'AlarmPllFault',
 'AlarmInputGeneralAlarm',
 'AlarmRectifierGeneralAlarm',
 'AlarmBoostGeneralAlarm',
 'AlarmInverterGeneralAlarm',
 'AlarmBatteryGeneralAlarm',
 'AlarmOutputOver',
 'AlarmOutputUnder',
 'AlarmBypassGeneralAlarm',
 'AlarmStopForOverload',
 'AlarmImminentStop',
 'AlarmModule1Alarm',
 'AlarmModule2Alarm',
 'AlarmModule3Alarm',
 'AlarmModule4Alarm',
 'AlarmModule5Alarm',
 'AlarmModule6Alarm',
 'AlarmExternalAlarm1',
 'AlarmExternalAlarm2',
 'AlarmExternalAlarm3',
 'AlarmExternalAlarm4',
 'AlarmEService',
 'AlarmRedundancyLost',
 'AlarmPeriodicServiceCheck',
 'AlarmAllTransferDisabled',
 'AlarmAutoTransferDisabled',
 'AlarmBatteryRoom',
 'AlarmManualBypass',
 'AlarmBatteryDischarged',
 'AlarmInsufficientResources',
 'AlarmOptionalBoards',
 'AlarmRectifierFault',
 'AlarmBoostFault',
 'AlarmInverterFault',
 'AlarmParallelModuleFault',
 'AlarmGenSetGeneral',
 'AlarmGenSetFault',
 'AlarmEmergencyStopActive',
 'AlarmBatteryCircuitOpen',
 'AlarmFansFailure',
 'AlarmPhaseRotationFault',
 'AlarmA62',
 'AlarmA63'
);
my $netvision_capacity      = "1.3.6.1.4.1.4555.1.1.1.1.2.4.0";
my $netvision_load_table    = "1.3.6.1.4.1.4555.1.1.1.1.4.4.1.4";
my $netvision_load1         = "1.3.6.1.4.1.4555.1.1.1.1.4.4.1.4.1";
my $netvision_load2         = "1.3.6.1.4.1.4555.1.1.1.1.4.4.1.4.2";
my $netvision_load3         = "1.3.6.1.4.1.4555.1.1.1.1.4.4.1.4.3";
my $netvision_voltage_table = "1.3.6.1.4.1.4555.1.1.1.1.3.3.1.2"; # voltage value * 10
my $netvision_voltage1      = "1.3.6.1.4.1.4555.1.1.1.1.3.3.1.2.1";
my $netvision_voltage2      = "1.3.6.1.4.1.4555.1.1.1.1.3.3.1.2.2";
my $netvision_voltage3      = "1.3.6.1.4.1.4555.1.1.1.1.3.3.1.2.3";

#
# General Battery Status check
#
my $general_battery_status = "1.3.6.1.2.1.33.1.2.1.0";
my $general_output_source  = "1.3.6.1.2.1.33.1.4.1.0";
my %upsBatteryStatuses = (
    1 => "unknown(1)",
    2 => "batteryNormal(2)",
    3 => "batteryLow(3)",
    4 => "batteryDepleted(4)"
);

my %upsOutputSources = (
    1 => "other(1)",
    2 => "none(2)",
    3 => "normal(3)",
    4 => "bypass(4)",
    5 => "battery(5)",
    6 => "booster(6)",
    7 => "reducer(7)"
);
my $general_output_voltage_table = "1.3.6.1.2.1.33.1.4.4.1.2";
my $general_output_current_table = "1.3.6.1.2.1.33.1.4.4.1.3";
my $general_output_power_table   = "1.3.6.1.2.1.33.1.4.4.1.4";
my $general_output_load_table    = "1.3.6.1.2.1.33.1.4.4.1.5";
my $general_capacity             = "1.3.6.1.2.1.33.1.2.4.0";
my $general_input_voltage_table  = "1.3.6.1.2.1.33.1.3.3.1.3";
my $general_input_current_table  = "1.3.6.1.2.1.33.1.3.3.1.4";
my $general_input_power_table    = "1.3.6.1.2.1.33.1.3.3.1.5";

#
# APC Automatic Transfer Switch (no UPS but ...)
#
my $apcats_base_MIB =	 "1.3.6.1.4.1.318"; # APC ATS base table
my $apcats_input_table = ".1.3.6.1.4.1.318.1.1.8.5.3.3.1.3";
my $apcats_input_a =	 ".1.3.6.1.4.1.318.1.1.8.5.3.3.1.3.1.1.1";
my $apcats_input_b =	 ".1.3.6.1.4.1.318.1.1.8.5.3.3.1.3.2.1.1";

# Globals

my $Version='1.1';

my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
my $o_timeout=  undef; 		# Timeout (Default 5)
my $o_perf=     undef;          # Output performance data
my $o_version2= undef;          # use snmp v2c
# check type  
my $o_check_type= "general";	# default NetVision
my @valid_types	=("general","netvision","socomec","apcats");
my $o_battery=  undef;          # string for option (w,c)
my $o_load=     undef;          # string for option (w,c)
my $o_w_load=	75;		# max used load warning level
my $o_c_load=	90;		# max used load warning level
my $o_w_battery=80;     	# min battery remaining critical level
my $o_c_battery=50;	        # min battery remaining critical level
my $o_voltage=  200;    	# max used voltage warnign level
my $o_output_lines=1;  	        # output lines used
my $o_input_lines=1;   	        # input lines used

# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3
my $v3protocols=undef;          # V3 protocol list.
my $o_authproto='md5';		# Auth protocol
my $o_privproto='des';		# Priv protocol
my $o_privpass= undef;		# priv password

# functions

sub p_version { print "check_snmp_ups version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -T (general|netvision|socomec|apcats) [-B <warn,crit>] [-O <warn,crit>] [-A <voltage>] [-f] [-t <timeout>] [-o <lines>] [-i <lines>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub set_status { # return worst status with this order : OK, unknwonw, warning, critical 
  my $new_status=shift;
  my $cur_status=shift;
  if (($cur_status == 0)|| ($new_status==$cur_status)){ return $new_status; }
  if ($new_status==3) { return $cur_status; }
  if ($new_status > $cur_status) {return $new_status;}
  return $cur_status;
}

sub help {
   print "\nSNMP UPS Monitor for Nagios version ",$Version,"\n";
   print "GPL Licence, (c)2009 Jürgen Vigna\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information 
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des) 
-P, --port=PORT
   SNMP port (Default 161)
-T, --type=general|netvision|socomec|apcats
	Environemental check : 
		general   : general UPS status
		netvision : voltage,battery,load and alerts
		socomec   : voltage,battery,load and alerts
		apcats    : input source, load
-B, --battery=<%battery left>
   Warning,Critical minimum battery level in percent (default: 80,50)
-O, --load=<max load>
   Warning,Critical Maximum Load of UPS before giving a warning (default: 75,90)
-A, --voltage=<max voltage>
   Warning Minimum Voltage of UPS before giving a warning (default: 200)
-o, --output_lines=<lines>
   Number of output lines to check (default: 1)
-i, --input_lines=<lines>
   Number of input lines to check (default: 1)
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
   	'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
	'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
	'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
	'X:s'	=> \$o_privpass,	'privpass:s'	=> \$o_privpass,
	'L:s'	=> \$v3protocols,	'protocols:s'	=> \$v3protocols,   
        't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,

	'2'     => \$o_version2,        'v2c'           => \$o_version2,
        'f'     => \$o_perf,            'perfparse'     => \$o_perf,
	'T:s'	=> \$o_check_type,	'type:s'	=> \$o_check_type,
        'B:s'   => \$o_battery,         'battery:s'    	=> \$o_battery,
        'O:s'   => \$o_load,            'load:s'        => \$o_load,
        'A:i'   => \$o_voltage,         'voltage:i'     => \$o_voltage,
        'o:i'   => \$o_output_lines,    'output_lines:i' => \$o_output_lines,
        'i:i'   => \$o_input_lines,     'input_lines:i' => \$o_input_lines
	);
    # check the -T option
    my $T_option_valid=0; 
    foreach (@valid_types) { if ($_ eq $o_check_type) {$T_option_valid=1} };
    if ( $T_option_valid == 0 ) 
    {print "Invalid check type (-T)!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Basic checks
    if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) 
        { print "Timeout must be >1 and <60 !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    if (!defined($o_timeout)) {$o_timeout=5;}
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_host) ) # check host and filter 
	{ print_usage(); exit $ERRORS{"UNKNOWN"}}
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
	  { print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    if ((defined($o_login) || defined($o_passwd)) && (defined($o_community) || defined($o_version2)) )
	  { print "Can't mix snmp v1,2c,3 protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    if (defined ($v3protocols)) {
        if (!defined($o_login)) { print "Put snmp V3 login info with protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
        my @v3proto=split(/,/,$v3protocols);
        if ((defined ($v3proto[0])) && ($v3proto[0] ne "")) {$o_authproto=$v3proto[0];	}	# Auth protocol
        if (defined ($v3proto[1])) {$o_privproto=$v3proto[1];	}	# Priv  protocol
        if ((defined ($v3proto[1])) && (!defined($o_privpass))) {
            print "Put snmp V3 priv login info with priv protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    }
    if (defined($o_battery)) {
        my @temp_array=split(/,/,$o_battery);
        if ($#temp_array != 1) {
            print "Battery Warning,Critical options wrong format use w,c \n";
            print_usage();
            exit $ERRORS{"UNKNOWN"};
        }
        $o_w_battery=$temp_array[0];
        $o_c_battery=$temp_array[1];
        if ($o_w_battery < $o_c_battery) {
            print "Battery Capacity Warning must be > Critical level\n";
            print_usage();
            exit $ERRORS{"UNKNOWN"};
        }
    }
    if (defined($o_load)) {
        my @temp_array=split(/,/,$o_load);
        verb("$o_load,$#temp_array ");
        if ($#temp_array != 1) {
            print "Load Warning,Critical options wrong format use w,c \n";
            print_usage();
            exit $ERRORS{"UNKNOWN"};
        }
        $o_w_load=$temp_array[0];
        $o_c_load=$temp_array[1];
        verb("-> $o_w_load,$o_c_load");
        if ($o_w_load > $o_c_load) {
            print "Load Warning must be < Critical level\n";
            print_usage();
            exit $ERRORS{"UNKNOWN"};
        }
    }
}

########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT + 5");
  alarm($TIMEOUT+5);
} else {
  verb("no global timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}

$SIG{'ALRM'} = sub {
 print "No answer from host\n";
 exit $ERRORS{"UNKNOWN"};
};

# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  verb("SNMPv3 login");
    if (!defined ($o_privpass)) {
  verb("SNMPv3 AuthNoPriv login : $o_login, $o_authproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -timeout          => $o_timeout
    );  
  } else {
    verb("SNMPv3 AuthPriv login : $o_login, $o_authproto, $o_privproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -privpassword	=> $o_privpass,
	  -privprotocol => $o_privproto,
      -timeout          => $o_timeout
    );
  }
} else {
	if (defined ($o_version2)) {
		# SNMPv2 Login
		verb("SNMP v2c login");
		  ($session, $error) = Net::SNMP->session(
		 -hostname  => $o_host,
		 -version   => 2,
		 -community => $o_community,
		 -port      => $o_port,
		 -timeout   => $o_timeout
		);
  	} else {
	  # SNMPV1 login
	  verb("SNMP v1 login");
	  ($session, $error) = Net::SNMP->session(
		-hostname  => $o_host,
		-community => $o_community,
		-port      => $o_port,
		-timeout   => $o_timeout
	  );
	}
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

my $exit_val=undef;
my $perfdata = undef;

if ($o_check_type eq "socomec") {
	$o_check_type="netvision";
}

#
### Now check general UPS statuses if available
#
my $general_exist=0;
my $global_status=0;
my $output="";

verb("Checking General UPS Status");
my @snmpoids;
push (@snmpoids,$general_battery_status);
push (@snmpoids,$general_output_source);

my $result = $session->get_request(-varbindlist => \@snmpoids);

if (defined($result)) {
	$general_exist=1;
	$general_battery_status = $result->{$general_battery_status};
	$general_output_source = $result->{$general_output_source};
	if (($general_output_source !~ /^noSuch/) && ($general_battery_status !~ /^noSuch/)) {
	    $output = "UPS State is ".$upsOutputSources{$general_output_source}.". Battery State is ".$upsBatteryStatuses{$general_battery_status}.".";

	    if ($general_output_source == 3) { # normal
	        $global_status = 0;
	    } elsif (($general_output_source == 6) || # booster
	        ($general_output_source == 7)) { # reducer
	        $global_status = 1;
	    } else {
	        $global_status = 2;
	    }

	    if (($global_status eq 0) && ($general_battery_status != 2)) { # battery low or depleted
	        $global_status = 1;
	    }
	}
}

if ($o_check_type eq "general") {
verb("Checking General UPS Values");
my $resultat;
my $output_exist=0;
my $input_exists=0;
my $capacity_exist=0;
my $status=0;

# Get Battery table
$resultat = (Net::SNMP->VERSION gt 4) ?
                  $session->get_request($general_capacity)
                : $session->get_request(-varbindlist => [$general_capacity]);

if (defined($resultat)) {
    $capacity_exist=1;
    my $capacity = $resultat->{$general_capacity};
    verb("OID : $general_capacity, Desc : $capacity");
    if ($capacity < $o_c_battery) {
        $status = 2;
        $output .= " Battery Level ($capacity)"
    } elsif ($capacity < $o_w_battery) {
        $status = 1;
        $output .= " Battery Level ($capacity)"
    }
    $perfdata .= " capacity=$capacity;$o_w_battery;$o_c_battery;0;100";
} else {
    verb("Capacity not found!")
}
$global_status=set_status($status,$global_status);

$status=0;
# Get Output Load per line
$resultat = (Net::SNMP->VERSION gt 4) ?
                  $session->get_table($general_output_load_table)
                : $session->get_table(Baseoid => $general_output_load_table);

if (defined($resultat)) {
    $output_exist=1;
    my $i=1;
    foreach my $key ( sort keys %$resultat) {
	if ($o_output_lines < $i) { next; }
        my $load = $$resultat{$key};
        verb("OID : $key, Desc : $load : $i");
        if ($load < 0) { next; }
        if ($load > $o_c_load) {
            $output .= " Load$i critical($load)";
            $status=2;
        } elsif ($load > $o_w_load) {
            $output .= " Load$i warning($load)";
            $status=1;
        }
        $perfdata .= " load$i=$load;$o_w_load;$o_c_load;0;100";
        $i++;
    }
} else {
	verb("OID: $general_output_load_table not found");
}
$global_status=set_status($status,$global_status);

$status=0;
# Get Output Voltage per line
$resultat = (Net::SNMP->VERSION gt 4) ?
                  $session->get_table($general_output_voltage_table)
                : $session->get_table(Baseoid => $general_output_voltage_table);

if (defined($resultat)) {
    $output_exist=1;
    my $i=1;
    foreach my $key ( sort keys %$resultat) {
	if ($o_output_lines < $i) { next; }
        my $voltage = $$resultat{$key};
        verb("OID : $key, Desc : $voltage : $i");
        if ($voltage < 0) { next; }
        if ($voltage < $o_voltage) {
            $output .= " Output Voltage$i warning($voltage)";
            $status=1;
        }
        $perfdata .= " output_voltage$i=$voltage;$o_voltage;0;0;380";
        $i++;
    }
} else {
	verb("OID: $general_output_voltage_table not found");
}
$global_status=set_status($status,$global_status);

$status=0;
# Get Input Voltage per line
$resultat = (Net::SNMP->VERSION gt 4) ?
                  $session->get_table($general_input_voltage_table)
                : $session->get_table(Baseoid => $general_input_voltage_table);

if (defined($resultat)) {
    $input_exists=1;
    my $i=1;
    foreach my $key ( sort keys %$resultat) {
	if ($o_input_lines < $i) { next; }
        my $voltage = $$resultat{$key};
        verb("OID : $key, Desc : $voltage : $i");
        if ($voltage < 0) { next; }
        if ($voltage < $o_voltage) {
            $output .= " Input Voltage$i warning($voltage)";
            $status=1;
        }
        $perfdata .= " input_voltage$i=$voltage;$o_voltage;0;0;380";
        $i++;
    }
} else {
	verb("OID: $general_input_voltage_table not found");
}
$global_status=set_status($status,$global_status);

if ($o_perf && defined($perfdata)) {
    $output .= "|$perfdata";
}

if ($global_status==0) {
  print "OK - All seems fine $output\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print "WARNING - $output\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print "CRITICAL - $output\n";
  exit $ERRORS{"CRITICAL"};
}

print "UNKNOWN - shouldn't be here\n";
exit $ERRORS{"UNKNOWN"};
}

############# Net Vision checks
if ($o_check_type eq "netvision") {

verb("Checking netvision ups");

my $resultat;
# status : 0=ok, 1=warning, 2=critial
my ($alerts_status,$capacity_status,$load_status,$voltage_status)=(0,0,0,0);
my ($alerts_exist,$capacity_exist,$load_exist,$voltage_exist)=(0,0,0,0);

# Get Alerts table
$resultat = (Net::SNMP->VERSION < 4) ?
                  $session->get_table($netvision_alert_table)
                : $session->get_table(Baseoid => $netvision_alert_table);

if (defined($resultat)) {
    $alerts_exist=1;
    my $i=0;
    foreach my $key ( keys %$resultat) {
        verb("OID : $key, Desc : $$resultat{$key} : $i");
        if ($$resultat{$key} != 0) {
            if ($alerts_status == 0) {
                $output = "Alerts aktiv:"
            }
            $alerts_status=1;
            $output .= " $netvision_alert_leaf[$i]($$resultat{$key})"
        }
        $i++;
    }
}

$global_status=set_status($alerts_status,$global_status);

# Get Battery table
$resultat = (Net::SNMP->VERSION < 4) ?
                  $session->get_request($netvision_capacity)
                : $session->get_request(-varbindlist => [$netvision_capacity]);

if (defined($resultat)) {
    $capacity_exist=1;
    my $capacity = $resultat->{$netvision_capacity};
    verb("OID : $netvision_capacity, Desc : $capacity");
    if ($capacity < $o_c_battery) {
        $capacity_status = 2;
        $output .= " Battery Level ($capacity)"
    } elsif ($capacity < $o_w_battery) {
        $capacity_status = 1;
        $output .= " Battery Level ($capacity)"
    }
    $perfdata .= " capacity=$capacity;$o_w_battery;$o_c_battery;0;100";
} else {
    verb("Capacity not found!")
}

$global_status=set_status($capacity_status,$global_status);

# Get Load table
$resultat = (Net::SNMP->VERSION < 4) ?
                  $session->get_table($netvision_load_table)
                : $session->get_table(Baseoid => $netvision_load_table);

if (defined($resultat)) {
    $load_exist=1;
    my $i=1;
    foreach my $key ( keys %$resultat) {
        my $load = $$resultat{$key};
        if ($load < 0) { next; }
        verb("OID : $key, Desc : $load : $i");
        if ($load > $o_c_load) {
            $output .= " Load$i critical($load)";
            $load_status=2;
        } elsif ($load > $o_w_load) {
            $output .= " Load$i warning($load)";
            $load_status=1;
        }
        $perfdata .= " load$i=$load;$o_w_load;$o_c_load;0;100";
        $i++;
    }
}

$global_status=set_status($load_status,$global_status);

# Get Voltage table
$resultat = (Net::SNMP->VERSION < 4) ?
                  $session->get_table($netvision_voltage_table)
                : $session->get_table(Baseoid => $netvision_voltage_table);

if (defined($resultat)) {
    $voltage_exist=1;
    my $i=1;
    foreach my $key ( keys %$resultat) {
        my $voltage = $$resultat{$key} / 10;
        if ($voltage < 0) { next; }
        verb("OID : $key, Desc : $voltage : $i");
        if ($voltage < $o_voltage) {
            $output .= " Voltage$i warning($voltage)";
            $voltage_status=1;
        }
        $perfdata .= " voltage$i=$voltage;$o_voltage;0;0;380";
        $i++;
    }
}

$global_status=set_status($voltage_status,$global_status);

$session->close;

verb ("status : $global_status");

if ( ($alerts_exist+$capacity_exist+$load_exist+$voltage_exist) == 0) {
  if ($general_exist) {
    $output .= " No special Netvision Data found";
  } else {
    print "No UPS informations found : UNKNOWN\n";
    exit $ERRORS{"UNKNOWN"};
  }
}

if ($o_perf && defined($perfdata)) {
    $output .= "|$perfdata";
}

if ($global_status==0) {
  print "OK - All seems fine $output\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print "WARNING - $output\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print "CRITICAL - $output\n";
  exit $ERRORS{"CRITICAL"};
}
}

############# APC ATS checks
if ($o_check_type eq "apcats") {

verb("Checking APC ATS");

my $resultat;
# status : 0=ok, 1=warning, 2=critial
my ($input_status,$capacity_status,$load_status,$voltage_status)=(0,0,0,0);
my ($input_exist,$capacity_exist,$load_exist,$voltage_exist)=(0,0,0,0);

# Get Alerts table
$resultat = (Net::SNMP->VERSION < 4) ?
                  $session->get_table($apcats_input_table)
                : $session->get_table(Baseoid => $apcats_input_table);

if (defined($resultat)) {
    $input_exist=1;
    my $i=0;
    my $temp;
    my $voltage;
    my $perfa;
    my $perfb;
    foreach my $key ( keys %$resultat) {
        verb("OID : $key, Desc : $$resultat{$key} : $i");
        $voltage=$$resultat{$key};
        if ($key =~ $apcats_input_a) {
            $temp="A";
            $perfa=" inputa=$voltage;$o_voltage;0;0;390";
        } elsif ($key =~ $apcats_input_b) {
            $temp="B";
            $perfb=" inputb=$voltage;$o_voltage;0;0;390";
        }
        if ($$resultat{$key} == 0) {
            $output .= " Input-$temp not connected";
            $input_status=2;
        } elsif ($voltage < $o_voltage) {
            $output .= " Input-$temp Voltage warning($voltage<$o_voltage)";
            if ($input_status < 2) {
                $input_status=1;
            }
        }
        $i++;
    }
    $perfdata.="$perfa $perfb";
}

$global_status=set_status($input_status,$global_status);

$session->close;

verb ("status : $global_status");

if ( ($input_exist+$capacity_exist+$load_exist+$voltage_exist) == 0) {
  if ($general_exist) {
    $output .= " No special APC Data found";
  } else {
    print "No UPS informations found : UNKNOWN\n";
    exit $ERRORS{"UNKNOWN"};
  }
}

if ($o_perf && defined($perfdata)) {
    $output .= "|$perfdata";
}

if ($global_status==0) {
  print "OK - All seems fine $output\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print "WARNING - $output\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print "CRITICAL - $output\n";
  exit $ERRORS{"CRITICAL"};
}
}

exit (3);
