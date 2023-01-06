#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 1
# https://adventofcode.com/2020/day/1

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example data
# my $lines = qq/
# 1721
# 979
# 366
# 299
# 675
# 1456
# /;
# @lines = grep { length $_ } split "\n", $lines;

# find two numbers in the input that sum to 2020
my %vals;
$vals{$_} = 1 foreach (@lines);

my $sum = 2020;
my $match;

foreach my $v ( keys %vals ) {
    if ( $vals{ $sum - $v } ) {
        $match = $v * ( $sum - $v );
        last;
    }
}

printf "Part 1: %s\n", $match;


# now we have to find three numbers that sum to 2020 - need a more complex algorithm
my @threes = keys %vals;

SEARCH:
foreach my $t (@threes) {
    delete $vals{$t};
    my $s = $sum - $t;
    foreach my $v ( keys %vals ) {
        if ( $vals{ $s - $v } ) {
            $match = $v * ( $s - $v ) * $t;
            last SEARCH;
        }
    }
}

printf "Part 2: %s\n", $match;
