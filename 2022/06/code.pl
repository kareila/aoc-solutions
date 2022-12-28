#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 6
# https://adventofcode.com/2022/day/6

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(mjqjpqmgbljsphdztnvjfqwrcgsmlb);
# @lines = split "\n", $lines;

# this time we only have one line, so never mind
my $line = $lines[0];

# look for the first position where the preceding 4 characters were all different
my $uniq = 4;
my $pos = 0;
my @chars;

my $init = sub {
    while ( $pos < $uniq ) {
        push @chars, substr( $line, $pos++, 1 );
    }
};

my $seek = sub {
    while ( $pos < length $line ) {
        my %hash = map { $_ => 1 } @chars;
        last if scalar keys %hash == $uniq;
        # move the window and keep seeking
        shift @chars;
        push @chars, substr( $line, $pos++, 1 );
    }
};

$init->();
$seek->();

printf "Part 1: %s\n", $pos;


# same code, but using 14 instead of 4
$uniq = 14;
$pos = 0;
@chars = ();

$init->();
$seek->();

printf "Part 2: %s\n", $pos;
