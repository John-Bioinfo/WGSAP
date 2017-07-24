#!/HOME/cheerland_1/WORKSPACE/soft/install/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

# Global variable
my ($help, $outDir);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2016-12-06
NOTE

USAGE
	$program <options>
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check
# Create Directory
system("mkdir -p $outDir/db") == 0 or die $!;

# Main

open OUTPUT, ">$outDir/CODEX.init.lst" or die $!;
system("mkdir -p $outDir/shell")  == 0 or die $!;
foreach my $name (1..22, 'X', 'Y') {
	open S, ">$outDir/shell/CODEX.init.chr$name.sh" or die $!;
	print S "Rscript /HOME/cheerland_1/WORKSPACE/pipeline/exome/db/CODEX/init/CODEX_init_chr.R chr$name /HOME/cheerland_1/WORKSPACE/pipeline/exome/test/CODEX/bam $outDir/db /HOME/cheerland_1/WORKSPACE/pipeline/exome/test/CODEX/bam/sampname init\n";
	close S;
	system ("Add_time_for_script.sh $outDir/shell/CODEX.init.chr$name.sh") == 0 or die $!;
	print OUTPUT "$outDir/shell/CODEX.init.chr$name.sh\n";
}
close OUTPUT;
