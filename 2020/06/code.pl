#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 6
# https://adventofcode.com/2020/day/6

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# abc
#
# a
# b
# c
#
# ab
# ac
#
# a
# a
# a
# a
#
# b
# /;
# @lines = split "\n", $lines;

my $group_size = 0;
my @members;
my @answers;
my %yes;

foreach my $l (@lines) {
    unless ( length $l ) {
        # finalize the current group
        push @answers, { %yes };
        push @members, $group_size;
        $group_size = 0;
        %yes = ();
        next;
    }

    $group_size++;
    $yes{$_}++ foreach split '', $l;  # no answers are repeated in a line
}

# need to close out final group if we didn't get a final blank line
push @answers, { %yes } if %yes;
push @members, $group_size if $group_size;

my $sum = 0;
$sum += scalar keys %$_ foreach @answers;

printf "Part 1: %s\n", $sum;


$sum = 0;
for ( my $i=0; $i < @members; $i++ ) {
    my $n = $members[$i] or next;
    my $a = $answers[$i];

    foreach my $v ( values %$a ) {
        $sum++ if $v == $n;  # number of yes responses == number of group members
    }
}

printf "Part 2: %s\n", $sum;
