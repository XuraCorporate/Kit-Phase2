#!/usr/bin/perl

## Usage BuildPorts <CsvFile> <Number of Ports>  <Network Name> [<Tenant Name (Default admin)>]

use strict;

my $DestFile=$ARGV[0];
my $NumOfPorts=$ARGV[1];
my $NetName=$ARGV[2] || 'provider-vlan723' ;
my $TenantName=$ARGV[3] || 'admin' ;


## Read all tenants
my %Tenant=();
foreach my $line (`keystone tenant-list`) {
	chomp $line ;
	$line =~ /(\S+)\s+\|\s+(\S+)/ or next;
	$Tenant{$2}=$1;
}

### Read all Networks
my %NetRec=();
foreach my $line (`neutron net-list -f csv`){
  chomp $line;
  my @field=split(/,/,$line);
  my $tmpAddr='0.0.0.';
  my $subnetID='';
  $field[2] =~ /([^\"\']+)[\"\'\s]+((\d+\.){3})/ or next;
  $tmpAddr=$2; 
  $subnetID=$1;
  $field[1]=~ s/[\"\']//g;
  $NetRec{$field[1]}={ Uid => $field[0] ,
					   SubNetUid => $subnetID ,
					   SubNetIP	=> $tmpAddr } ;
}

### Verify Before continue
exists $Tenant{$TenantName} or die "Can't find Tenant $TenantName";
exists $NetRec{$NetName} or die "Can't find Network $NetName" ;

### Verify Range:
my $Cmd="neutron subnet-show -f value $NetRec{$NetName}->{SubNetUid}";
my @Range=();
foreach my $line (`$Cmd`) {
   chomp $line;
   $line =~ /start.+?([\d\.]+).+?([\d\.]+)/ or next;
   my ($Start,$End)=($1,$2);
   $Start = $Start =~ /(\d+)$/ ? $1 : 3;
   $End = $End =~ /(\d+)$/ ? $1 : 13;
   @Range=($Start,$End);
   last;
}

## list of available IPs
my %allocatedIps=();
foreach my $line (`neutron  port-list -f csv -c "fixed_ips"`) {
	chomp $line;
	my @Field=split(/[\:,]/,$line);
	$Field[1] =~ /$NetRec{$NetName}->{SubNetUid}/ or next;
	#print "Field: $Field[1]\n";
	#print "Net:   $NetRec{$NetName}->{SubNetUid}\n" ;
	my $tmpIP= $Field[3] =~ /([\d\.]+)/ ? $1 : '0.0.0.0';
	print "Debug - ID $Field[1] ,$tmpIP\n";
	$allocatedIps{$tmpIP}=1;
}
my @CsvList=();
for ( my $i = $Range[0] ; $i < $Range[1] ; $i++ ) {
	my $ip=sprintf("%s%d",$NetRec{$NetName}->{SubNetIP},$i);
	exists $allocatedIps{$ip} and next;
	my $Cmd="neutron port-create --fixed-ip ip_address=$ip --tenant-id $Tenant{$TenantName} $NetName" ;
	print "$Cmd\n";
	my $Rec={};
	foreach my $line (`$Cmd`) {
		chomp($line);
		my @Field=split(/\s*\|\s+/,$line);
		$Field[2] =~ s/\s+\|//;
		$Rec->{$Field[1]}=$Field[2];
	}
	push(@CsvList,"$Rec->{id},$Rec->{mac_address},$ip");
	$NumOfPorts--;
	$NumOfPorts or last;
}
open(Out,">$DestFile");
print Out join("\n",@CsvList);
close (Out);

# keystone tenant-list

# neutron port-create --fixed-ip ip_address=10.107.203.250 --tenant-id 4507ca536d42408093e0fb10d336c275 provider-vlan723