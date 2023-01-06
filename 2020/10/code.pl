#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 10
# https://adventofcode.com/2020/day/10

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# 28
# 33
# 18
# 42
# 31
# 14
# 46
# 20
# 48
# 47
# 24
# 23
# 49
# 45
# 19
# 38
# 39
# 11
# 1
# 32
# 25
# 35
# 8
# 17
# 7
# 9
# 4
# 2
# 34
# 10
# 3
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @sorted = sort { $a <=> $b } @lines;
push @sorted, 3 + $sorted[-1];  # device value

my $current_rating = 0;
my %differences;

foreach my $adapter ( @sorted ) {
    my $diff = $adapter - $current_rating;
    die "Difference too big for $adapter" if $diff > 3; # not allowed
    $differences{$diff}++;
    $current_rating = $adapter;
}

printf "Part 1: %s\n", $differences{3} * $differences{1};


my %counts = ( 0 => 1 );

for ( my $i=0; $i < @sorted; $i++ ) {
    my $a = $sorted[$i];
    $counts{$a} = ( $counts{ $a - 3 } // 0 )
                + ( $counts{ $a - 2 } // 0 )
                + ( $counts{ $a - 1 } // 0 );
}

# sums accumulate such that the final value contains the total number of possibilities
printf "Part 2: %s\n", $counts{ $sorted[-1] };
