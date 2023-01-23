#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 13
# https://adventofcode.com/2021/day/13

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 6,10
# 0,14
# 9,10
# 0,3
# 10,4
# 4,11
# 6,0
# 6,12
# 4,1
# 0,13
# 10,12
# 3,4
# 3,0
# 8,4
# 1,10
# 2,14
# 8,10
# 9,0
#
# fold along y=7
# fold along x=5
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @points = grep { /,/ } @lines;
my @folds = grep { /=/ } @lines;

my @rows;

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    $rows[$y]->[$x] = $v;
};

my $point_value = sub {
    my ( $x, $y ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return unless $rows[$y];     # ugh, this would auto-vivify an empty row
    return $rows[$y]->[$x];      # going off the grid is merely undefined
};

foreach ( @points ) {
    my ( $x, $y ) = split /,/;
    $set_value->( $x, $y, 1 );
}

# dots will never appear exactly on a fold line

my $sum = 0;
foreach ( @folds ) {
    my ( $axis, $val ) = /\s([xy])=(\d+)$/;
    if ( $axis eq 'y' ) {
        # fold up towards zero
        for ( my $j = $#rows; $j > $val; $j-- ) {
            $rows[$j] //= [];
            my $y = 2 * $val - $j;
            for ( my $i=0; $i < @{ $rows[$j] }; $i++ ) {
                my $u = $point_value->( $i, $j );
                my $v = $point_value->( $i, $y );
                $set_value->( $i, $y, $u || $v );
            }
            $#rows--;
        }
    } else {  # 'x'
        # fold left towards zero
        for ( my $j=0; $j < @rows; $j++ ) {
            $rows[$j] //= [];
            for ( my $i = scalar @{ $rows[$j] } - 1; $i > $val ; $i-- ) {
                my $x = 2 * $val - $i;
                my $u = $point_value->( $i, $j );
                my $v = $point_value->( $x, $j );
                $set_value->( $x, $j, $u || $v );
            }
            $rows[$j] = [ splice @{ $rows[$j] }, 0, $val ];
        }
    }

    if ( $sum == 0 ) {
        foreach (@rows) {
            $sum += $_ // 0 foreach @$_;
        }
        printf "Part 1: %s\n", $sum;
    }
}

my $code = join "\n", map { join '', map { $_ ? '#' : '.' } @$_ } @rows;

printf "Part 2: \n%s\n", $code;
