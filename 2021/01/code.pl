#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 1
# https://adventofcode.com/2021/day/1

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example input
# @lines = qw(
# 199
# 200
# 208
# 210
# 200
# 207
# 240
# 269
# 260
# 263
# );

my $num_increases = 0;
my $prev;

foreach my $l (@lines) {
    $prev = $l and next unless defined $prev;
    $num_increases++ if $l > $prev;
    $prev = $l;
}

printf "Part 1: %s\n", $num_increases;


$num_increases = 0;
$prev = undef;

for ( my $i=2; $i < scalar @lines; $i++ ) {
    my $window = $lines[$i-2] + $lines[$i-1] + $lines[$i];
    $prev = $window and next unless defined $prev;
    $num_increases++ if $window > $prev;
    $prev = $window;
}

printf "Part 2: %s\n", $num_increases;
