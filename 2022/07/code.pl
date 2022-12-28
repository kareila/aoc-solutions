#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 7
# https://adventofcode.com/2022/day/7

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# $ cd /
# $ ls
# dir a
# 14848514 b.txt
# 8504156 c.dat
# dir d
# $ cd a
# $ ls
# dir e
# 29116 f
# 2557 g
# 62596 h.lst
# $ cd e
# $ ls
# 584 i
# $ cd ..
# $ cd ..
# $ cd d
# $ ls
# 4060174 j
# 8033020 d.log
# 5626152 d.ext
# 7214296 k
# );
# @lines = split "\n", $lines;

my %tree;
my $curdir;
my %orgdirs;
my $maxdepth = 0;

foreach my $l (@lines) {
    next unless $l;

    # change directory
    if ( $l =~ /^\$ cd (.+)$/ ) {
        my $d = $1;
        if ( $d eq '/' ) {        # special case: root directory
            $curdir = '/';
        } elsif ( $d eq '..' ) {  # special case: parent directory
            die "Can't cd .. above /" if $curdir eq '/';
            $curdir =~ s:([^/]+)\/$::;   # e.g. /a/b/c/ -> /a/b/
        } else {
            $curdir .= "$d/";     # use full path to avoid duplicate name collisions
        }
        $tree{$curdir} //= [0];   # size is first array element

        # track depth to avoid "deep recursion" later
        my $depth = grep { $_ eq '/' } split '', $curdir;  # count the slashes
        $orgdirs{$depth} //= [];
        push @{ $orgdirs{$depth} }, $curdir;
        $maxdepth = $depth if $depth > $maxdepth;
    }

    # list contents (always used with no arguments), no-op
    next if $l eq '$ ls';

    # directory contains another directory
    if ( $l =~ /^dir (.+)$/ ) {
        push @{ $tree{$curdir} }, $1;
    }

    # directory contains a file, just count the size
    if ( $l =~ /^(\d+) / ) {
        @{ $tree{$curdir} }[0] += $1;
    }
}

my $find_size = sub {
    my ( $dir ) = @_;
    die "Directory '$dir' not found" unless $tree{$dir};
    my @c = @{ $tree{$dir} };   # directory contents
    my $size_files = shift @c;
    foreach my $d ( map { "$dir$_/" } @c ) {
        # I had originally planned to recurse here, but it died on the full data set.
        # Instead, make sure the subdirectories have been calculated already.
        $size_files += $tree{$d}->[0];
    }
    $tree{$dir} = [ $size_files ];   # only retain total size
    return $size_files;
};

for ( my $i = $maxdepth; $i > 0; $i-- ) {
    next unless $orgdirs{$i};
    foreach my $d ( @{ $orgdirs{$i} } ) {
        $find_size->($d);   # work in layers from bottom to top
    }
}

# flatten the data structure: dir name => dir size
my %sizes = map { $_ => $tree{$_}->[0] } keys %tree;

my $total = 0;
foreach my $v ( values %sizes ) {
    $total += $v if $v <= 100000;
}

printf "Part 1: %s\n", $total;


my $current_freespace = 70000000 - $sizes{'/'};
my $amount_to_delete = 30000000 - $current_freespace;

# Find the smallest directory that, if deleted, would free up enough space.
my $candidate;

foreach my $v ( values %sizes ) {
    if ( $v >= $amount_to_delete ) {
        $candidate = $v unless defined $candidate && $candidate < $v;
    }
}

printf "Part 2: %s\n", $candidate;
