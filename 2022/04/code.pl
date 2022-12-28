#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 4
# https://adventofcode.com/2022/day/4

local $/ = '';

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my $lines = <$fh>; close $fh;
my @lines = split "\n", $lines;

# Example data:
# no warnings 'qw';
# @lines = qw(
# 2-4,6-8
# 2-3,4-5
# 5-7,7-9
# 2-8,3-7
# 6-6,4-6
# 2-6,4-8
# );

# one assignment fully contains the other if start is <= and end is >=

my $total = 0;

foreach my $l (@lines) {
    my ( $a_start, $a_end, $b_start, $b_end ) = ( $l =~ m/^(\d+)\-(\d+),(\d+)\-(\d+)$/ );
    if ( $a_start <= $b_start && $a_end >= $b_end ) {  # a contains b
        $total++;
        next;  # avoid the corner case where both ranges are equal
    }
    if ( $b_start <= $a_start && $b_end >= $a_end ) {  # b contains a
        $total++;
    }
}

printf "Part 1: %s\n", $total;


# go through entire range looking for any overlaps

$total = 0;

foreach my $l (@lines) {
    my ( $a_start, $a_end, $b_start, $b_end ) = ( $l =~ m/^(\d+)\-(\d+),(\d+)\-(\d+)$/ );

    # I always figure out a way to use hashes eventually.
    my @a = ($a_start .. $a_end);
    my @b = ($b_start .. $b_end);
    my %uniq;

    map { $uniq{$_} = 1 } (@a, @b);

    # I don't need to know which values were duplicated, so...
    $total++ if scalar( keys %uniq ) != scalar @a + scalar @b;
}

printf "Part 2: %s\n", $total;
