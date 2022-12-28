#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 3
# https://adventofcode.com/2022/day/3

local $/ = '';

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my $lines = <$fh>; close $fh;
my @lines = split "\n", $lines;

# Calculate the "priority" value of the character representing an item.
# Use a leading zero to adjust the index value to begin at 1.

my $priority = sub {
    my $index = '0abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return index $index, $_[0];
};

# Split each input line in half, then see which character appears in each half.

my $process_line = sub {
    my ( $l ) = @_;

    my $len = length($l) / 2;  # we can trust length to be even

    my $s1 = substr( $l, 0, $len );
    my $s2 = substr( $l, $len );

    my %s = ( 1 => {}, 2 => {} );
    my $n = 1;

    foreach my $s ( $s1, $s2 ) {
        my $i = 0;
        while ($i < $len) {
            my $c = $priority->( substr($s, $i++, 1) );
            $s{$n}->{$c} = 1;
        }
        $n++;
    }

    # find the one key that is used in both hashes
    foreach ( keys %{$s{1}} ) {
        return $_ if $s{2}->{$_};  # returns the priority value
    }

    die "No match found!\n";
};

# This is redone below to test a more general solution.
#
# my $total = 0;
#
# foreach my $l (@lines) {
#     $total += $process_line->($l);
# }
#
# printf "Part 1: %s\n", $total;


# For the second part, instead of comparing two halves of one line,
# we are comparing each group of three lines to find the item in common,
# so we need to generalize our approach to handle any number of strings.

my $find_common = sub {
    my @s = @_;

    # initialize data hash based on number of input elements
    my %s;
    for ( my $q = 1; $q <= scalar @s; $q++ ) {
        $s{$q} = {};
    }

    my $n = 1;

    # Using $s, @s, and %s like this is confusing. Make better choices than I did.

    foreach my $s ( @s ) {
        my $i = 0;
        while ( $i < length $s ) {
            my $c = $priority->( substr($s, $i++, 1) );
            $s{$n}->{$c} = 1;
        }
        $n++;
    }

    # flatten the hash and look for the element with the highest value
    my %counts;

    foreach my $d ( values %s ) {
        foreach my $c ( keys %$d ) {
            $counts{$c}++;
            # quit as soon as we find the value we need
            return $c if $counts{$c} == scalar @s;
        }
    }

    die "No match found!\n";
};

# redo the first part using the general approach

my $total = 0;

foreach my $l (@lines) {
    my $len = length($l) / 2;  # we can trust length to be even

    my $s1 = substr( $l, 0, $len );
    my $s2 = substr( $l, $len );

    $total += $find_common->($s1, $s2);
}

printf "Part 1: %s\n", $total;


# Example data:
# @lines = qw(
# vJrwpWtwJgWrhcsFMMfFFhFp
# jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
# PmmdzqPrVvPwwTWBwg
# wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
# ttgJtRGJQctTZtZT
# CrZsJsPPZsGzwwsLwLmpwMDw
# );

# now compare groups of three lines

$total = 0;

for ( my $q = 0; $q < scalar @lines; $q += 3 ) {
    my @group = ( $lines[$q], $lines[$q+1], $lines[$q+2] );
    $total += $find_common->(@group);
}

printf "Part 2: %s\n", $total;
