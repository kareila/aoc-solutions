#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 3
# https://adventofcode.com/2020/day/3

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# ..##.......
# #...#...#..
# .#....#..#.
# ..#.#...#.#
# .#...##..#.
# ..#.##.....
# .#.#.#....#
# .#........#
# #.##...#...
# #...##....#
# .#..#...#.#
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $len = length( shift @lines );

my $check_slope = sub {
    my $step = $_[0];
    my $pos = 0;
    my $num = 0;

    foreach my $l (@lines) {
        $pos += $step;
        $pos -= $len if $pos >= $len;
        $num++ if substr( $l, $pos, 1 ) eq '#';
    }

    return $num;
};

printf "Part 1: %s\n", $check_slope->(3);


my @results;

push @results, $check_slope->(1);
push @results, $check_slope->(3);
push @results, $check_slope->(5);
push @results, $check_slope->(7);

# rewrite @lines to avoid changing $check_slope
my @every_other_line;

for ( my $i=1; $i < @lines; $i += 2 ) {
    push @every_other_line, $lines[$i];
}

@lines = @every_other_line;
push @results, $check_slope->(1);

my $product = 1;
$product *= $_ foreach @results;

printf "Part 2: %s\n", $product;
