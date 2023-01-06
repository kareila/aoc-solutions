#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 2
# https://adventofcode.com/2020/day/2

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example data
# my $lines = qq/
# 1-3 a: abcde
# 1-3 b: cdefg
# 2-9 c: ccccccccc
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $valid = 0;

my $parse_line = sub {
    my $pattern = '^(\d+)-(\d+) ([a-z]): (\w+)$';
    my ( $min, $max, $chr, $pw ) = ( $_[0] =~ qr/$pattern/ );
    die "Line does not match: $_[0]\n" unless $pw;

    my $num_found = 0;
    foreach my $c ( split '', $pw ) {
        $num_found++ if $c eq $chr;
    }

    $valid++ if $num_found >= $min && $num_found <= $max;
};

$parse_line->($_) foreach @lines;

printf "Part 1: %s\n", $valid;


# same inputs, new meanings
$valid = 0;

$parse_line = sub {
    my $pattern = '^(\d+)-(\d+) ([a-z]): (\w+)$';
    my ( $pos1, $pos2, $chr, $pw ) = ( $_[0] =~ qr/$pattern/ );
    die "Line does not match: $_[0]\n" unless $pw;

    my $c1 = substr( $pw, ($pos1 - 1), 1 );
    my $c2 = substr( $pw, ($pos2 - 1), 1 );

    my $num_found = 0;
    $num_found++ if $chr eq $c1;
    $num_found++ if $chr eq $c2;

    $valid++ if $num_found == 1;
};

$parse_line->($_) foreach @lines;

printf "Part 2: %s\n", $valid;
