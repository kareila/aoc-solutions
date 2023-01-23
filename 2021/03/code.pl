#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 3
# https://adventofcode.com/2021/day/3

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example input
# @lines = qw(
# 00100
# 11110
# 10110
# 10111
# 10101
# 01111
# 00111
# 11100
# 10000
# 11001
# 00010
# 01010
# );

my $decode_binary = sub {
    my @num = reverse split '', $_[0];
    my $val = 0;

    for ( my $i=0; $i < @num; $i++ ) {
        $val += 2 ** $i if $num[$i];
    }

    return $val;
};

# count number of lines and number of ones in each column
# we can assume each line has the same number of columns

my $mid = scalar(@lines) / 2;
my %count;

foreach my $l (@lines) {
    my @cols = split '', $l;
    my $i = 1;

    foreach my $c (@cols) {
        $count{$i++} += $c;
    }
}

my $gamma = '';
my $epsil = '';

foreach my $c ( sort { $a <=> $b } keys %count ) {
    $gamma .= $count{$c} > $mid ? 1 : 0;
    $epsil .= $count{$c} > $mid ? 0 : 1;
}

my $d_g = $decode_binary->( $gamma );
my $d_e = $decode_binary->( $epsil );

printf "Part 1: gamma %s, epsilon %s, product is %s\n", $d_g, $d_e, $d_g * $d_e;


# We want to repeat the process for finding gamma & epsilon, but with
# the reduced set of numbers after each iteration, not the entire set.
#
# This can be expressed as a function where the only difference between
# the two values is whether we keep the most common number (1) or least
# common (0). Ties are resolved in favor of 1 for most, and 0 for least.

my @colnum = split '', $gamma;  # convenient constant from previous calculation

my $filter_vals = sub {
    my $crit = $_[0] ? 1 : 0;
    my %search = map { $_ => 1 } (0 .. $#lines);
    my $n = 0;

    foreach (@colnum) {
        my $count = 0;

        foreach my $i (keys %search) {
            my $c = substr $lines[$i], $n, 1;
            $search{$i} = $c;
            $count += $c;
        }

        my $mid = scalar(keys %search) / 2;
        my $keep = $count < $mid ? !$crit : $crit;

        foreach my $i (keys %search) {
            delete $search{$i} unless $search{$i} == $keep;
        }

        if ( scalar(keys %search) == 1 ) {
            return $lines[ (keys %search)[0] ];
        }
        $n++;
    }
};

my $oxy = $filter_vals->(1);
my $co2 = $filter_vals->(0);

my $d_o = $decode_binary->( $oxy );
my $d_c = $decode_binary->( $co2 );

printf "Part 2: oxygen %s, CO2 %s, product is %s\n", $d_o, $d_c, $d_o * $d_c;
