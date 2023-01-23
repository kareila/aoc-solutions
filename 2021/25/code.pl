#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 25
# https://adventofcode.com/2021/day/25

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# v...>>.vv>
# .vv>>.vv..
# >>.>v>...v
# >>v>>.>.v.
# v>v.vv.v..
# >.>>..v...
# .vv..>.>v.
# v.v..>>v.v
# ....v..v.>
# );
# @lines = grep { length $_ } split "\n", $lines;

# At first glance, this looks like a simpler version of 2022 Day 24.

my $max_x = length $lines[0];
my $max_y = scalar @lines;

my @rows = map { [ split '' ] } @lines;

my $point_value = sub {
    my ( $x, $y ) = @_;

# commenting out safety rails to speed things up
#
#     return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
#     return unless $rows[$y];     # ugh, this would auto-vivify an empty row

    return $rows[$y]->[$x] // '.';  # assume undefined values are empty spaces
};

my @work;

my $set_value = sub {
    my ( $x, $y, $v ) = @_;

# commenting out safety rails to speed things up
#
#     return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array

    return $work[$y]->[$x] = $v;
};

my $advance_right = sub {
    my ( $x, $y ) = @_;
    my $v = $point_value->( $x, $y );
    my $next_x = ( $x + 1 ) % $max_x;

    if ( $v eq '>' && $point_value->( $next_x, $y ) eq '.' ) {
        $set_value->( $x, $y, '.' );
        $set_value->( $next_x, $y, '>' );
    }
};

my $advance_down = sub {
    my ( $x, $y ) = @_;
    my $v = $point_value->( $x, $y );
    my $next_y = ( $y + 1 ) % $max_y;

    if ( $v eq 'v' && $point_value->( $x, $next_y ) eq '.' ) {
        $set_value->( $x, $y, '.' );
        $set_value->( $x, $next_y, 'v' );
    }
};

my $update_rows = sub {
    for ( my $j = 0; $j < $max_y; $j++ ) {
        for ( my $i = 0; $i < $max_x; $i++ ) {
            $rows[$j]->[$i] = $work[$j]->[$i] if defined $work[$j]->[$i];
        }
    }
    @work = ();
};

my $minutes = 0;

my $tick = sub {
    for ( my $j = 0; $j < $max_y; $j++ ) {
        for ( my $i = 0; $i < $max_x; $i++ ) {
            $advance_right->( $i, $j );
        }
    }
    $update_rows->();

    for ( my $j = 0; $j < $max_y; $j++ ) {
        for ( my $i = 0; $i < $max_x; $i++ ) {
            $advance_down->( $i, $j );
        }
    }
    $update_rows->();

    $minutes++;
};

my $grid_state = sub { join "\n", map { join '', @$_ } @rows };
my $current_state = $grid_state->();

while (1) {
    $tick->();
    my $g = $grid_state->();
    last if $g eq $current_state;
    $current_state = $g;
}

printf "Part 1: %s\n", $minutes;
# # elapsed time: approx. 16 sec

# There is no Part 2!  Merry Christmas!
