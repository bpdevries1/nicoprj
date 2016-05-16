#!D:/apps/Perl/bin/perl -w

# TODO:
# - check typeperf doesn't run before start
# - check typeperf runs after start and file exists

use strict;
use Getopt::Long; #  qw(:config require_order);
use Cwd;
use open ':utf8';	# to suppress warnings about Wide characters...
use Data::Dump qw(dump ddx);

$, = "\t";		# set output field separator
$\ = "\n";		# set output record separator

### Options

my $help     = 0;
my $verbose  = 0;

my $g = GetOptions (
	'help'     => \$help,
	'verbose'  => \$verbose,
	);
	
if (($help == 1) || ($#ARGV < 2)) {
	print "Usage:\n\tgenerate-Typeperf-from-template.pl tsv templatedir outdir [looptag]";
	exit 0;
}

my $looptag = '^LOOP: ';

my $tsv = shift @ARGV;
	$tsv = Cwd::abs_path($tsv);
my $templatedir = shift @ARGV;
	unless (-e $templatedir) {
		print "Templatedir $templatedir not found";
		exit 1;
	}
my $outdir = shift @ARGV;
	unless (-e $outdir) {
		print "Making dir: $outdir" if ($verbose > 0);
		mkdir $outdir;
	}
my @loop = &getLoop($tsv);
if ($#ARGV >= 0) {
	$looptag = shift @ARGV;
}

for my $fn (&grepdir($templatedir,'^[^\.]')) {	# regular files only
	my @lines = &readFile("$templatedir/$fn");
	my @outlines = ();
	for my $line (@lines) {
		if ($line =~ /$looptag/) {
			for my $ix (0..$#loop) {
				(my $tmp = $line) =~ s/$looptag//;
				while (my ($key, $value) = each(%{$loop[$ix]})) {
					$tmp =~ s/$key/$value/g;
				}
				push @outlines, $tmp;
			}
		}
		else {
			push @outlines, $line;
		}
	}
	&writeFile("$outdir/$fn",@outlines);
}
exit 0;

# ==== Subs ========================================================================

sub getLoop() {
	my ($tsv) = @_;
	my @data = &loadTSV($tsv);	
	my $errors = 0;
	my %colnr = ();
	my @header = @{$data[0]};
	for my $col (0..$#header) {
		my $str = $header[$col];
		if (defined $colnr{$str}) {
			print "Duplicate column for $str at $colnr{$str} and $col";
			$errors++;
		}
		else {
			$colnr{$str} = $col;
		}
	}
	my @loop = ();
	my $size = $#header;
	for my $ix (1..$#data) {
		my %values = ();
		my @row = @{$data[$ix]};
		if ($#row != $size) {
			print "Row with index $ix has different size than header";
			$errors++;
		}
		else {
			for my $col (0..$#row) {
				$values{$header[$col]} = $row[$col];
			}
			push @loop, \%values;
		}
	}
	exit 1 if ($errors > 0);
	@loop;
}

sub grepdir() {
	my ($dir,$pattern) = @_;

	my $DH;
	opendir($DH, $dir) || die "can't opendir $dir: $!";
	my @tmpfiles = grep { /$pattern/ } readdir($DH);
	closedir $DH;
	return @tmpfiles;
}

sub readFile() {
	my ($fn) = @_;

	unless (-e $fn) {
		print "	Error reading file: \"$fn\" doesn't exist";
		return ();
	}
	open (TMP,"<$fn") || die "can't open for reading $fn: $!";
	my @lines = <TMP>;
	close TMP;
	foreach (@lines) {
		chomp;
	}
	return @lines;
}

sub writeFile() {
	my ($fn,@lines) = @_;

	open (TMP,">$fn") || die "can't open for writing $fn: $!";
	for my $line (@lines) {
		print TMP $line;
	}
	close TMP;
}

sub loadTSV() {
	my ($fn) = @_;

	my @lines = &readFile($fn);
	my @tablines = ();
	for my $line (@lines) {
		chomp $line;
		push @tablines, [split("\t",$line)];
	}
	return @tablines;
}

