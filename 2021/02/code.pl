#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 2
# https://adventofcode.com/2021/day/2

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example input
# @lines = (
# 'forward 5',
# 'down 5',
# 'forward 8',
# 'up 3',
# 'down 8',
# 'forward 2'
# );

my $pos = 0;
my $depth = 0;

foreach my $l (@lines) {
    my ( $move, $amt ) = split ' ', $l;

    $pos += $amt if $move eq 'forward';

    $depth += $amt if $move eq 'down';
    $depth -= $amt if $move eq 'up';
}

printf "Part 1: position %s, depth %s, product is %s\n", $pos, $depth, $pos * $depth;


$pos = 0;
$depth = 0;
my $aim = 0;

foreach my $l (@lines) {
    my ( $move, $amt ) = split ' ', $l;

    $aim += $amt if $move eq 'down';
    $aim -= $amt if $move eq 'up';

    if ( $move eq 'forward' ) {
        $pos += $amt;
        $depth += $aim * $amt;
    }
}

printf "Part 2: position %s, depth %s, product is %s\n", $pos, $depth, $pos * $depth;
