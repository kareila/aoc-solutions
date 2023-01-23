#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 20
# https://adventofcode.com/2021/day/20

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# ..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
#
# #..#.
# #....
# ##..#
# ..#..
# ..###
# );
# @lines = grep { length $_ } split "\n", $lines;

my $enhance_vals = shift @lines;

my @rows;
my $init_rows = sub { @rows = map { [ split '' ] } grep { length $_ } @lines };
$init_rows->();

my $default_val = '.';  # value of off-grid pixels (can change on enhancement)

my $point_value = sub {
    my ( $x, $y ) = @_;
    ( $x, $y ) = @$x if ref $x;  # allow arrayref arguments for simplicity's sake

    my $def = $default_val;

    return $def if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return $def unless $rows[$y];     # ugh, this would auto-vivify an empty row

    return $rows[$y]->[$x] // $def;  # going off the grid is merely undefined
};

my $view_grid = sub {
    my $p = sub { ref $_[0] ? ( @{ $_[0] } > 1 ? scalar @{ $_[0] } : $_[0]->[0] ) : $_[0] };
    foreach my $r ( @rows ) {
        print join '', map { $p->($_) } @$r;
        print "\n";
    }
};

# For consistency, use a temporary working grid that gets copied over when completed.
my @work;

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array

    return $work[$y]->[$x] = $v;
};

my $as_decimal = sub {
    my ( $binnum ) = @_;
    my $len = length $binnum;
    my $number = 0;
    for ( my $i = 1; $i <= $len; $i++ ) {
        my $digit = substr $binnum, $len - $i, 1;
        my $mult = 2 ** ( $i - 1 );
        $number += $digit * $mult;
    }
    return $number;
};

# look at 3x3 grid centered on pixel, return enhanced value
my $consider = sub {
    my ( $x, $y ) = @_;
    my $str = '';

    foreach ( [ $x - 1, $y - 1 ], [ $x, $y - 1 ], [ $x + 1, $y - 1 ],
              [ $x - 1, $y - 0 ], [ $x, $y - 0 ], [ $x + 1, $y - 0 ],
              [ $x - 1, $y + 1 ], [ $x, $y + 1 ], [ $x + 1, $y + 1 ] ) {
        $str .= $point_value->($_);  # no undef case here
    }
    $str =~ tr/#\./10/;
    return substr $enhance_vals, $as_decimal->($str), 1;
};

# The first value of the enhance string determines the value
# of every "off-grid" unlit pixel after an enhancement.
my $first_val = substr $enhance_vals, 0, 1;

# The last value of the enhance string determines the value
# of every "off-grid" lit pixel after an enhancement.
my $last_val = substr $enhance_vals, -1, 1;

my $step = sub {
    # Step 1: extend grid one additional pixel in each direction.
    my $def = $default_val;
    foreach my $r (@rows) { $r = [ $def, @$r, $def ]; }
    my @empty_row = map { $def } ( 1 .. @{ $rows[0] } );
    @rows = ( [ @empty_row ], @rows, [ @empty_row ] );

    # Step 2: enhance every pixel in the grid.
    for ( my $j = 0; $j < @rows; $j++ ) {
        for ( my $i = 0; $i < @{ $rows[0] }; $i++ ) {
            $set_value->( $i, $j, $consider->($i,$j) );
        }
    }
    # Step 3: copy @work to @rows, and reset @work.
    for ( my $j = 0; $j < @rows; $j++ ) {
        for ( my $i = 0; $i < @{ $rows[0] }; $i++ ) {
            $rows[$j]->[$i] = $work[$j]->[$i] // $def;
        }
    }
    @work = ();

    # Step 4: update value of unmapped pixels.
    $default_val = $default_val eq '#' ? $last_val : $first_val;
};

my $count_pixels = sub {
    my $c = 0;
    $c += scalar grep { $_ eq '#' } @$_ foreach @rows;
    return $c;
};

$step->() foreach (1..2);

printf "Part 1: %s\n", $count_pixels->();


$init_rows->();
$step->() foreach (1..50);

printf "Part 2: %s\n", $count_pixels->();
# elapsed time: approx. 11 sec
