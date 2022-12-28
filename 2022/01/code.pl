#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 1
# https://adventofcode.com/2022/day/1

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;

# Note: reading the lines into an array requires chomping each line below.
# Alternative approach would be to read them into one long string and split on \n.

my %totals;
my $n;

# Normally I would use "foreach @lines" here, but using a numeric index
# gives us a ready-to-use unique value to assign to $n for the hash key.

foreach my $i ( 0 .. $#lines ) {
    unless (defined $n) {
        # start a new accumulator for this section of input
        $n = $i;
        $totals{$n} = 0;
    }
    my $l = $lines[$i];
    chomp $l;       # remember this doesn't return the string value for assignment
    unless ($l) {
        # end of section (blank line)
        $n = undef;
        next;
    }
    $totals{$n} += $l;
}

my @results = reverse sort { $a <=> $b } values %totals;        # default sort is ascii
printf "Part 1: %s\n", $results[0];


my $top3 = $results[0] + $results[1] + $results[2];
printf "Part 2: %s\n", $top3;
