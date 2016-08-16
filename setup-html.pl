#!/usr/bin/perl
# convert test setup details to a html table

use strict;
use warnings;
use Cwd;
use File::Basename;
use HTML::Entities;
use Getopt::Std;
use POSIX;
use URI::Escape;

my $now = strftime("%FT%TZ", gmtime);

my %opts;
getopts('d:', \%opts) or do {
    print STDERR "usage: $0 -d date\n";
    exit(2);
};
my $date = $opts{d} or die "No -d specified";

my $dir = dirname($0). "/..";
chdir($dir)
    or die "Chdir to '$dir' failed: $!";
my $regressdir = getcwd();
$dir = "results/$date";
chdir($dir)
    or die "Chdir to '$dir' failed: $!";

my %h;
foreach my $version (glob("version-*.txt")) {
    my ($host) = $version =~ m,version-(.*)\.txt,;
    open(my $fh, '<', $version)
	or die "Open '$version' for reading failed: $!";
    defined(my $line = <$fh>)
	or next;
    my ($time, $short) = $line =~ m,: ((\w+ \w+ \d+) .*)$,;
    $h{$host} = {
	version => $version,
	time => $time,
	short => $short,
    };
}
foreach my $setup (glob("setup-*.log")) {
    my ($host) = $setup =~ m,setup-(.*)\.log,;
    $h{$host}{setup} = $setup,
}

open(my $html, '>', "setup.html")
    or die "Open 'setup.html' for writing failed: $!";
print $html "<!DOCTYPE html>\n";
print $html "<html>\n";
print $html "<head>\n";
print $html "  <title>OpenBSD Test Setup</title>\n";
print $html "</head>\n";

print $html "<body>\n";
print $html "<h1>OpenBSD regress test machine</h1>\n";
print $html "<table>\n";
print $html "  <tr>\n    <th>setup at</th>\n";
print $html "    <td>$now</td>\n";
print $html "  </tr>\n";
print $html "  <tr>\n    <th>test at</th>\n";
print $html "    <td>$date</td>\n";
print $html "  </tr>\n";
print $html "</table>\n";
print $html "<table>\n";
print $html "  <tr>\n    <th>machine</th>\n";
print $html "    <th>version</th>\n";
print $html "    <th>setup</th>\n";
print $html "  </tr>\n";

foreach my $host (sort keys %h) {
    print $html "  <tr>\n    <th>$host</th>\n";
    my $version = uri_escape($h{$host}{version});
    my $time = encode_entities($h{$host}{time});
    my $short = $h{$host}{short};
    my $setup = uri_escape($h{$host}{setup});
    if ($version) {
	print $html "    <td title=\"$time\">".
	    "<a href=\"$version\">$short</a></td>\n";
    } else {
	print $html "    <td></td>";
    }
    if ($setup) {
	print $html "    <td><a href=\"$setup\">log</a></td>\n";
    } else {
	print $html "    <td></td>";
    }
    print $html "  </tr>\n";
}
print $html "</table>\n";
print $html "</body>\n";

print $html "</html>\n";
close($html)
    or die "Close 'setup.html' after writing failed: $!";