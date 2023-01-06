#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 11
# https://adventofcode.com/2020/day/11

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# L.LL.LL.LL
# LLLLLLL.LL
# L.L.L..L..
# LLLL.LL.LL
# L.LL.LL.LL
# L.LLLLL.LL
# ..L.L.....
# LLLLLLLLLL
# L.LLLLLL.L
# L.LLLLL.LL
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @rows;
my $init_rows = sub {
    @rows = ();
    push @rows, [ split '' ] foreach @lines;
};
$init_rows->();

# die sprintf "%s\n", join "\n", map { join '', @$_ } @rows;

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

my $get_adjacent_num_occupied = sub {
    my ( $x, $y ) = @_;
    my $count = 0;

    foreach ( [ $x - 1, $y - 1 ], [ $x, $y - 1 ], [ $x + 1, $y - 1 ],
              [ $x - 1, $y ],                     [ $x + 1, $y ],
              [ $x - 1, $y + 1 ], [ $x, $y + 1 ], [ $x + 1, $y + 1 ] ) {
        $count++ if ( $point_value->( @$_ ) // '.' ) eq '#';
    }
    return $count;
};

my $apply_empty_rule = sub {
    my $count = 0;
    my @queue;
    for ( my $j=0; $j < scalar @rows; $j++ ) {
        for ( my $i=0; $i < length $lines[0]; $i++ ) {
            if ( $point_value->( $i, $j ) eq 'L' ) {
                if ( $get_adjacent_num_occupied->( $i, $j ) == 0 ) {
                    push @queue, [ $i, $j ];
                    $count++;
                }
            }
        }
    }
    # do all operations at once to maintain a consistent state
    $set_value->( @$_, '#' ) foreach @queue;
    return $count;
};

my $occupied_tolerance = 4;

my $apply_occupied_rule = sub {
    my $count = 0;
    my @queue;
    for ( my $j=0; $j < scalar @rows; $j++ ) {
        for ( my $i=0; $i < length $lines[0]; $i++ ) {
            if ( $point_value->( $i, $j ) eq '#' ) {
                if ( $get_adjacent_num_occupied->( $i, $j ) >= $occupied_tolerance ) {
                    push @queue, [ $i, $j ];
                    $count++;
                }
            }
        }
    }
    # do all operations at once to maintain a consistent state
    $set_value->( @$_, 'L' ) foreach @queue;
    return $count;
};

my $num_occupied_seats = sub {
    my $count = 0;
    for ( my $j=0; $j < scalar @rows; $j++ ) {
        $count += scalar grep { $_ eq '#' } @{ $rows[$j] };
    }
    return $count;
};

my $seek_equilibrium = sub {
    my $last_num_changed;
    my $do_empty = 1;

    until ( defined $last_num_changed && $last_num_changed == 0 ) {
        $last_num_changed = $do_empty ? $apply_empty_rule->() : $apply_occupied_rule->();
        $do_empty = $do_empty ? 0 : 1;
    }
};

$seek_equilibrium->();

printf "Part 1: %s\n", $num_occupied_seats->();


# Two changes:
# 1. Look for the first non-floor space in eight directions, not just adjacent.
# 2. Tolerance of occupied seats goes up from 4 to 5.

$occupied_tolerance = 5;

sub first_chair_in_direction {
    my ( $x, $y, $x_diff, $y_diff ) = @_;
    my $v = $point_value->( $x + $x_diff, $y + $y_diff );
    return 0 unless defined $v;  # off the grid
    return 0 if $v eq 'L';  # empty
    return 1 if $v eq '#';  # occupied
    return first_chair_in_direction( $x + $x_diff, $y + $y_diff, $x_diff, $y_diff );
};

$get_adjacent_num_occupied = sub {
    my ( $x, $y ) = @_;
    my $count = 0;

    foreach ( [ -1, -1 ], [ 0, -1 ], [ 1, -1 ], [ -1, 0 ], [ 1, 0 ],
              [ -1,  1 ], [ 0,  1 ], [ 1,  1 ] ) {
        $count += first_chair_in_direction( $x, $y, @$_ );
    }
    return $count;
};

$init_rows->();
$seek_equilibrium->();

printf "Part 2: %s\n", $num_occupied_seats->();
