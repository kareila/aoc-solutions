#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 25
# https://adventofcode.com/2022/day/25

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# 1=-0-2
# 12111
# 2=0=
# 21
# 2=01
# 111
# 20012
# 112
# 1=-1=
# 1-12
# 12
# 1=
# 122
# );
# @lines = grep { length $_ } split "\n", $lines;

my $parse_snafu = sub {
    my ( $str ) = @_;
    my $len = length $str;
    my $number = 0;

    for ( my $i = 1; $i <= $len; $i++ ) {
        my $pos = $len - $i;
        my $mult = 5 ** ( $i - 1 );
        my $digit = substr $str, $pos, 1;

        my $d = { 2=>2, 1=>1, 0=>0, '-' => -1, '=' => -2 }->{ $digit };
        $number += $d * $mult;
    }
    return $number;
};

my $sum = 0;
$sum += $parse_snafu->($_) foreach @lines;

my $output_snafu = sub {
    my ( $num ) = @_;
    my $max_place = 1;
    my @col;

    until ( $num == 0 ) {
        my $mod = ( 5 ** $max_place );
        my $bit = $num % $mod / ( 5 ** ( $max_place - 1 ) );
        $num -= $num % $mod;
        $max_place++;

        if ( $bit < 3 ) {
            push @col, $bit;
        } else {
            push @col, ( $bit == 3 ) ? '=' : '-';
            $num += $mod;
        }
    }
    return join '', reverse @col;
};

printf "Part 1: %s\n", $output_snafu->( $sum );

# There is no Part 2!  Merry Christmas!
