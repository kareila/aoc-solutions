#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 15
# https://adventofcode.com/2020/day/15

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/0,3,6/;
# @lines = grep { length $_ } split "\n", $lines;

my @numbers = split ',', $lines[0];   # single line of input today
my @spoken;  # array is about 25% faster than a hash on Part 2
my $t = 1;

$spoken[$_] = $t++ foreach @numbers[ 0 .. $#numbers - 1 ];  # initialization step

my $next_number = sub {
    my $prev = $numbers[-1];
    my $speak = $spoken[$prev] ? $t - $spoken[$prev] : 0;
    @numbers = ($speak);  # don't need to preserve history
    $spoken[$prev] = $t++;
    warn "Round $t...\n" unless $t % 5000000;
};

$next_number->() while $t < 2020;

printf "Part 1: %s\n", $numbers[-1];


$next_number->() while $t < 30000000;

printf "Part 2: %s\n", $numbers[-1];

# elapsed time: approx. 13 seconds for both parts together
