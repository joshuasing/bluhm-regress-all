#!/usr/bin/perl
# convert netlink test results to a html tables

# Copyright (c) 2016-2022 Alexander Bluhm <bluhm@genua.de>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use strict;
use warnings;
use Cwd;
use File::Basename;
use File::Find;
use HTML::Entities;
use Getopt::Std;
use POSIX;
use URI::Escape;

use lib dirname($0);
use Html;
use Testvars qw(%TESTDESC);

my $now = strftime("%FT%TZ", gmtime);

my %opts;
getopts('h:lv', \%opts) or do {
    print STDERR <<"EOF";
usage: netlink-html.pl [-l] [-h host]
    -h host	user and host for version information, user defaults to root
    -l		create latest.html with one column of the latest results
    -v		verbose
EOF
    exit(2);
};
my $date = $opts{d};
my $verbose = $opts{v};
$| = 1 if $verbose;
@ARGV and die "No arguments allowed";

my $netlinkdir = dirname($0). "/..";
chdir($netlinkdir)
    or die "Change directory to '$netlinkdir' failed: $!";
$netlinkdir = getcwd();
my $resultdir = "$netlinkdir/results";
if ($date && $date =~ /^(current|latest|latest-\w+)$/) {
    my $current = readlink("$resultdir/$date")
	or die "Read link '$resultdir/$date' failed: $!";
    -d "$resultdir/$current"
	or die "Test directory '$resultdir/$current' failed: $!";
    $date = basename($current);
}
chdir($resultdir)
    or die "Change directory to '$resultdir' failed: $!";

my ($user, $host) = split('@', $opts{h} || "", 2);
($user, $host) = ("root", $user) unless $host;

my @HIERARCHY = qw(date cvsdate patch iface pseudo repeat btrace);
my (%T, %D, %H);

# %T
# $test				test directory relative to /usr/src/regress/
# $T{$test}{severity}		weighted severity of all failures of this test
# $date				date and time when test was executed as string
# $T{$test}{$date}{status}	result of this test at that day
# $T{$test}{$date}{message}	test printed a pass duration or failure summary
# $T{$test}{$date}{logfile}	relative path to net.log for hyper link
# %D
# $date				date and time when test was executed as string
# $D{$date}{pass}		percentage of not skipped tests that passed
# $D{$date}{short}		date without time
# $D{$date}{result}		path to test.result file
# $D{$date}{setup}		relative path to setup.html for hyper link
# $D{$date}{version}		relative path to version.txt for hyper link
# $D{$date}{host}		hostname of the machine running the regress
# $D{$date}{dmesg}		path to dmesg.txt of machine running regress
# $D{$date}{diff}		path to diff.txt custom build kernel cvs diff
# $D{$date}{kernel}		sysctl kernel version string
# $D{$date}{kerntime}		build time in kernel version string
# $D{$date}{location}		user at location of kernel build
# $D{$date}{build}		snapshot or custom build
# $D{$date}{arch}		sysctl hardware machine architecture
# $D{$date}{ncpu}		sysctl hardware ncpu cores

print "glob_result_files" if $verbose;
my @result_files = glob_result_files();
print "\nparse result files" if $verbose;
parse_result_files(@result_files);
print "\ncreate html hier files" if $verbose;
write_html_hier_files($date);
print "\nwrite html date file" if $verbose;
write_html_date_file();
print "\n" if $verbose;

exit;

sub list_dates {
    my @dates = shift || reverse sort keys %D;
    return @dates;
}

sub html_hier_top {
    my ($html, $date, @cvsdates) = @_;
    my $dv = $D{$date};
    print $html <<"HEADER";
<table>
  <tr>
    <th>created at</th>
    <td>$now</td>
  </tr>
  <tr>
    <th>run at</th>
    <td><a href="../$date/netlink.html">$date</a></td>
  </tr>
HEADER
    print $html "</table>\n";
}

sub html_hier_test_head {
    my ($html, @hiers) = @_;

    foreach my $hier (@HIERARCHY) {
	print $html "  <tr>\n    <th></th>\n";
	print $html "    <th>$hier</th>\n";
	foreach my $hv (@hiers) {
	    my $title = "";
	    my $name = $hv->{$hier} || "";
	    if ($hier =~ /date$/) {
		my $time = encode_entities($name);
		$title = "  title=\"$time\"";
		$name =~ s/T.*//;
	    }
	    print $html "    <th$title>$name</th>\n";
	}
	print $html "  </tr>\n";
    }
}

sub html_hier_test_row {
    my ($html, $test, $td, @hiers) = @_;

    (my $testcmd = $test) =~ s/_/ /g;
    print $html "  <tr>\n    <th class=\"desc\">", $TESTDESC{$test} || "",
	"</th>\n";
    print $html "    <td class=\"test\"><code>$testcmd</code></td>\n";
    foreach my $hv (@hiers) {
	my $tv = $td->{$hv->{key}};
	my $status = $tv->{status} || "";
	my $class = " class=\"status $status\"";
	my $message = encode_entities($tv->{message});
	my $title = $message ? " title=\"$message\"" : "";
	my $logfile = $tv->{logfile};
	my $link = uri_escape($logfile, "^A-Za-z0-9\-\._~/");
	my $href = $logfile ? "<a href=\"../$link\">" : "";
	my $enda = $href ? "</a>" : "";
	print $html "    <td$class$title>$href$status$enda</td>\n";
    }
    print $html "  </tr>\n";
}

sub write_html_hier_files {
    my @dates = list_dates(shift);

    foreach my $date (@dates) {
	print "." if $verbose;
	my $dv = $D{$date};
	my $short = $dv->{short};

	my ($html, $htmlfile) = html_open("$date/netlink");
	my @nav = (
	    Top      => "../../../test.html",
	    All      => "../netlink.html",
	    Latest   => "../latest/netlink.html",
	    Running  => "../run.html");
	html_header($html, "OpenBSD Netlink Hierarchie",
	    "OpenBSD netlink $short test results",
	    @nav);

	my $hv = $H{$date};
	html_hier_top($html, $date, @$hv);

	print $html "<table>\n";
	html_hier_test_head($html, @$hv);

	my @tests = sort { $T{$b}{severity} <=> $T{$a}{severity} || $a cmp $b }
	    keys %T;
	foreach my $test (@tests) {
	    my $td = $T{$test}{$date}
		or next;
	    html_hier_test_row($html, $test, $td, @$hv);
	}
	print $html "</table>\n";

	html_status_table($html, "netlink");
	html_footer($html);
	html_close($html, $htmlfile);
    }
}

sub write_html_date_file {
    my $file = $opts{l} ? "latest" : "netlink";
    $file .= "-$host" if $host;
    my ($html, $htmlfile) = html_open($file);
    my $topic = $host ? ($opts{l} ? "latest $host" : $host) :
	($opts{l} ? "latest" : "all");

    my $typename = "Netlink";
    my @nav = (
	Top     => "../../test.html",
	All     => ($opts{l} || $host ? "netlink.html" : undef),
	Latest  => ($opts{l} ? undef :
	    $host ? "latest-$host/netlink.html" : "latest/netlink.html"),
	Running => "run.html");
    html_header($html, "OpenBSD $typename Results",
	"OpenBSD ". lc($typename). " $topic test results",
	@nav);

    print $html <<"HEADER";
<table>
  <tr>
    <th>created at</th>
    <td>$now</td>
  </tr>
</table>
HEADER

    print "." if $verbose;
    my @dates = reverse sort keys %D;
    print $html "<table>\n";
    print $html "  <tr>\n    <th>pass rate</th>\n";
    foreach my $date (@dates) {
	my $passrate = $D{$date}{pass};
	$passrate /= $D{$date}{total} if $D{$date}{total};
	my $percent = "";
	$percent = sprintf("%d%%", 100 * $passrate) if defined $passrate;
	print $html "    <th>$percent</th>\n";
    }
    print $html "  <tr>\n    <th>run at date</th>\n";
    foreach my $date (@dates) {
	my $short = $D{$date}{short};
	my $time = encode_entities($date);
	my $hierhtml = "$date/netlink.html";
	my $link = uri_escape($hierhtml, "^A-Za-z0-9\-\._~/");
	my $href = -f $hierhtml ? "<a href=\"$link\">" : "";
	my $enda = $href ? "</a>" : "";
	print $html "    <th title=\"$time\">$href$short$enda</th>\n";
    }
    print $html "  <tr>\n    <th>machine</th>\n";
    foreach my $date (@dates) {
	my $setup = $D{$date}{setup};
	my $link = uri_escape($setup, "^A-Za-z0-9\-\._~/");
	my $href = $setup ? "<a href=\"$link\">" : "";
	my $enda = $href ? "</a>" : "";
	print $html "    <th>${href}setup info$enda</th>\n";
    }
    print $html "  <tr>\n    <th>architecture</th>\n";
    foreach my $date (@dates) {
	my $arch = $D{$date}{arch};
	my $dmesg = $D{$date}{dmesg};
	my $link = uri_escape($dmesg, "^A-Za-z0-9\-\._~/");
	my $href = $dmesg ? "<a href=\"$link\">" : "";
	my $enda = $href ? "</a>" : "";
	print $html "    <th>$href$arch$enda</th>\n";
    }
    print $html "  <tr>\n    <th>host</th>\n";
    foreach my $date (@dates) {
	my $hostname = $D{$date}{host};
	my $hostlink;
	if (!$host || $opts{l}) {
	    $hostlink = "netlink-$hostname.html";
	    undef $hostlink unless -f $hostlink;
	}
	my $href = $hostlink ? "<a href=\"$hostlink\">" : "";
	my $enda = $href ? "</a>" : "";
	print $html "    <th>$href$hostname$enda</th>\n";
    }
    print $html "  </tr>\n";

    my @tests = sort { $T{$b}{severity} <=> $T{$a}{severity} || $a cmp $b }
	keys %T;
    foreach my $test (@tests) {
	print "." if $verbose;
	print $html "  <tr>\n    <th>$test</th>\n";
	foreach my $date (@dates) {
	    my $tv = $T{$test}{$date};
	    my $status = $tv->{status} || "";
	    my $class = " class=\"status $status\"";
	    my $message = encode_entities($tv->{message});
	    my $title = $message ? " title=\"$message\"" : "";
	    my $hierhtml = "$date/netlink.html";
	    my $link = uri_escape($hierhtml, "^A-Za-z0-9\-\._~/");
	    my $href = -f $hierhtml ? "<a href=\"$link\">" : "";
	    my $enda = $href ? "</a>" : "";
	    print $html "    <td$class$title>$href$status$enda</td>\n";
	}
	print $html "  </tr>\n";
    }
    print $html "</table>\n";

    html_status_table($html, "netlink");
    html_footer($html);
    html_close($html, $htmlfile);
}

sub glob_result_files {
    print "." if $verbose;

    my @files;
    my $wanted = sub {
	/^test.result$/ or return;
	my %f;
	$File::Find::dir =~ s,^\./,,;
	$File::Find::name =~ s,^\./,,;
	my @dirs = split(m,/,, $File::Find::dir);
	$_ = shift @dirs;
	unless (defined && /^[0-9-]+T[0-9:]+Z/) {
	    warn "Invalid date '$_' in result '$File::Find::name'";
	    return;
	}
	$f{date} = $_;
	$_ = shift @dirs;
	if (defined && /^[0-9-]+T[0-9:]+Z$/) {
	    $f{cvsdate} = $_;
	    $_ = shift @dirs;
	}
	if (defined && /^patch-/) {
	    $f{patch} = $_;
	    $_ = shift @dirs;
	}
	if (defined && /^iface-/) {
	    $f{iface} = $_;
	    $_ = shift @dirs;
	}
	if (defined && /^pseudo-/) {
	    $f{pseudo} = $_;
	    $_ = shift @dirs;
	}
	if (defined && /^[0-9]{3}$/) {
	    $f{repeat} = $_;
	    $_ = shift @dirs;
	}
	if (defined && /^btrace-/) {
	    $f{btrace} = $_;
	    $_ = shift @dirs;
	}
	if (defined) {
	    warn "Invalid subdir '$_' in result '$File::Find::name'";
	    return;
	}
	$f{dir} = $File::Find::dir;
	$f{name} = $File::Find::name;
	push @files, \%f;
    };

    if ($opts{l}) {
	my @latest;
	if ($host) {
	    @latest = "latest-$host";
	    -d $latest[0]
		or die "No latest test.result for $host";
	} else {
	    @latest = grep { -d } glob("latest-*");
	}
	find($wanted, map { (readlink($_) or die
	    "Readlink latest '$_' failed: $!") }  @latest);
	return sort { $a->{dir} cmp $b->{dir} } @files;
    }

    find($wanted, ".");
    if ($host) {
	return sort { $a->{dir} cmp $b->{dir} }
	    grep { -f "$_->{date}/version-$host.txt" } @files;
    } else {
	return sort { $a->{dir} cmp $b->{dir} } @files;
    }
}

# fill global hashes %T %D %H
sub parse_result_files {
    foreach my $file (@_) {
	print "." if $verbose;

	# parse result file
	my ($date, $short) = $file->{date} =~ m,^(([^/]+)T[^/]+Z)$,
	    or next;
	my $dv = $D{$date} ||= {
	    short => $short,
	    result => $file->{name},
	    pass => 0,
	    total => 0,
	};
	$dv->{setup} = "$date/setup.html" if -f "$date/setup.html";
	$_->{severity} *= .5 foreach values %T;
	my %hiers;
	foreach my $hier (@HIERARCHY) {
	    my $subdir = $file->{$hier}
		or next;
	    $hiers{$hier} = $subdir;
	}
	my $hk = join($;, map { $file->{$_} || "" } @HIERARCHY);
	$hiers{key} = $hk;
	my $hv = $H{$date} ||= [];
	push @$hv, \%hiers;
	my ($total, $pass) = (0, 0);
	open(my $fh, '<', $file->{name})
	    or die "Open '$file->{name}' for reading failed: $!";
	my @values;
	while (<$fh>) {
	    chomp;
	    my ($status, $test, $message) = split(" ", $_, 3);
	    if ($status =~ /VALUE/) {
		next if $status =~ /SUBVALUE/;  # XXX not yet
		my (undef, $number, $unit, $name) = split(" ", $_, 4);
		$number =~ /^(\d+|\d*\.\d+)$/
		    or warn "Number '$number' for value '$name' is invalid";
		push @values, {
		    name => $name || "",
		    unit => $unit,
		    number => $number,
		};
		next;
	    }
	    my $tv = $T{$test}{$date}{$hk} ||= {};
	    $tv->{status}
		and warn "Duplicate test '$test' at '$file->{name}'";
	    $tv->{status} = $status;
	    $tv->{message} = $message;
	    my $logfile = "$file->{dir}/logs/$test.log";
	    $tv->{logfile} = $logfile if -f $logfile;
	    my $severity = status2severity($status);
	    $T{$test}{severity} += $severity;
	    $total++ unless $status eq 'SKIP' || $status eq 'XFAIL';
	    $pass++ if $status eq 'PASS';
	    $tv = $T{$test}{$date};
	    if (($tv->{severity} || 0) < $severity) {
		$tv->{status} = $status;
		$tv->{severity} = $severity;
	    }
	}
	close($fh)
	    or die "Close '$file->{name}' after reading failed: $!";
	$dv->{pass} += $pass;
	$dv->{total} += $total;

	# parse version file
	foreach my $version (sort glob("$date/version-*.txt")) {
	    $version =~ m,/version-(.+)\.txt$,;
	    my $hostname = $1;

	    next if $dv->{version};
	    $dv->{version} = $version;
	    $dv->{host} ||= $hostname;
	    (my $dmesg = $version) =~ s,/version-,/dmesg-,;
	    $dv->{dmesg} ||= $dmesg if -f $dmesg;
	    (my $diff = $version) =~ s,/version-,/diff-,;
	    $dv->{diff} ||= $diff if -s $diff;

	    %$dv = (parse_version_file($version), %$dv);
	}
	$dv->{build} = ($dv->{location} =~ /^deraadt@\w+.openbsd.org:/) ?
	    "snapshot" : "custom";
    }
}
