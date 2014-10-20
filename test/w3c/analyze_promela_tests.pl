#!/usr/bin/perl -w

use strict;
use File::Spec;
use File::Basename;
use Data::Dumper;

my $toBaseDir = File::Spec->canonpath(dirname($0));
my $outDir   = File::Spec->catfile($toBaseDir, 'graphs');
my $testResultFile;

my @dataQuery;

# iterate given arguments and populate $dataQuery
foreach my $argnum (0 .. $#ARGV) {
	if ($argnum == $#ARGV) {
		if (-f $ARGV[$argnum]) {
			$testResultFile = $ARGV[$argnum];
			last;
		}
		if (-f File::Spec->catfile($toBaseDir, $ARGV[$argnum])) {
			$testResultFile = File::Spec->catfile($toBaseDir, $ARGV[$argnum]);
			last;
		}
	}
	push(@dataQuery, \[split('\.', $ARGV[$argnum])]);
}

if (!$testResultFile) {
	$testResultFile = File::Spec->catfile($toBaseDir, "../../build/cli/Testing/Temporary/LastTest.log");
}

open(FILE, $testResultFile) or die $!;
mkdir($outDir) or die($!) if (! -d $outDir);

my $test;
my $block;
my $currTest;
my $testIndex = 0;

$/ = '-' x 58 . "\n";

while ($block = <FILE>) {
	chomp($block);
	
	# Test Preambel ========
	if ($block =~ 
		/
			\n?
			(\d+)\/(\d+)\sTesting:\s(.*)\n
			(\d+)\/(\d+)\sTest:\s(.*)\n
		/x ) {
		$currTest = $3;
		$test->{$currTest}->{'name'} = $currTest;
		$test->{$currTest}->{'number'} = $1;
		$test->{$currTest}->{'total'} = $2;
		$test->{$currTest}->{'index'} = $testIndex++;
		
		if ($currTest =~ /test(\d+\w?)\.scxml$/) {
			$test->{$currTest}->{'w3c'} = $1;
		}
		
		next;
	}
	
	# Test Epilog ========
	if ($block =~ 
		/
			Test\s(\S+)\sReason:\n
		/x ) {
		$test->{$currTest}->{'status'} = lc($1);
		next;
	}
	
	# Promela Test ========
	if ($block =~ 
		/
			Approximate\sComplexity:\s(\d+)\n
			Actual\sComplexity:\s(\d+)\n
		/x ) {
		$test->{$currTest}->{'flat'}->{'apprComplexity'} = $1;
		$test->{$currTest}->{'flat'}->{'actualComplexity'} = $2;
		
		if ($block =~ /State-vector (\d+) byte, depth reached (\d+), errors: (\d+)/) {
			$test->{$currTest}->{'pml'}->{'states'}->{'stateSize'} = $1;
			$test->{$currTest}->{'pml'}->{'states'}->{'depth'} = $2;
			$test->{$currTest}->{'pml'}->{'states'}->{'errors'} = $3;
		}
		if ($block =~ 
			/
				\s+(\d+)\sstates,\sstored\s\((\d+)\svisited\)\n
				\s+(\d+)\sstates,\smatched\n
				\s+(\d+)\stransitions\s\(=\svisited\+matched\)\n
				\s+(\d+)\satomic\ssteps\n
				hash\sconflicts:\s+(\d+)\s\(resolved\)
			/x ) {
			$test->{$currTest}->{'pml'}->{'states'}->{'stateStored'} = $1;
			$test->{$currTest}->{'pml'}->{'states'}->{'stateVisited'} = $2;
			$test->{$currTest}->{'pml'}->{'states'}->{'stateMatched'} = $3;
			$test->{$currTest}->{'pml'}->{'states'}->{'transitions'} = $4;
			$test->{$currTest}->{'pml'}->{'states'}->{'atomicSteps'} = $5;
			$test->{$currTest}->{'pml'}->{'hashConflicts'} = $6;
		}
		
		if ($block =~ 
			/
				\s+([\d\.]+)\sequivalent\smemory\susage\sfor\sstates.*
				\s+([\d\.]+)\sactual\smemory\susage\sfor\sstates\n
				\s+([\d\.]+)\smemory\sused\sfor\shash\stable\s\(-w(\d+)\)\n
				\s+([\d\.]+)\smemory\sused\sfor\sDFS\sstack\s\(-m(\d+)\)
				\s+([\d\.]+)\stotal\sactual\smemory\susage
			/x ) {
			$test->{$currTest}->{'pml'}->{'memory'}->{'states'} = $1;
			$test->{$currTest}->{'pml'}->{'memory'}->{'actual'} = $2;
			$test->{$currTest}->{'pml'}->{'memory'}->{'hashTable'} = $3;
			$test->{$currTest}->{'pml'}->{'memory'}->{'hashLimit'} = $4;
			$test->{$currTest}->{'pml'}->{'memory'}->{'dfsStack'} = $5;
			$test->{$currTest}->{'pml'}->{'memory'}->{'dfsLimit'} = $6;
			$test->{$currTest}->{'pml'}->{'memory'}->{'total'} = $7;
		}

		next;
	}
	
}
close(FILE);

if (@dataQuery > 0) {
	while (my ($name, $data) = each $test) {
		my $seperator = "";
		foreach (@dataQuery) {
			my $currVal = $data;
			my @query = @${$_};
			foreach (@query) {
				my $dataKey = $_;
				if (defined($currVal->{$dataKey})) {
					$currVal = $currVal->{$dataKey};
				} else {
					die("no key $dataKey in structure:\n" . Dumper($currVal));
				}
			}
			print $seperator . $currVal;
			$seperator = ", ";
		}
		print "\n";
	}
} else {
	while (my ($name, $data) = each $test) {
		# get one $data into scope
		print "Available Queries:\n";

		sub dumpQueries() {
			my $structure = shift;
			my $path = shift || "";
			while (my ($name, $data) = each $structure) {
				if (ref(\$data) eq "SCALAR") {
					print "\t" . $path . $name . "\n";
				} else {
					&dumpQueries($data, $path . $name . ".");
				}
			}
		}
		&dumpQueries($data);
		exit;
	}
}
