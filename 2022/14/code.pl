#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 14
# https://adventofcode.com/2022/day/14

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# 498,4 -> 498,6 -> 496,6
# 503,4 -> 502,4 -> 502,9 -> 494,9
# );
# @lines = split "\n", $lines;

my @cols;
my $max_y = 0;

# Out of curiosity, I tried changing @cols to use a hash instead of an array in
# order to use less memory, but it took MORE time - 4.8sec vs 3.6sec on the full
# data set. Even just changing it from x,y to y,x took slightly longer.

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array

    $cols[$x]->[$y] = $v;
};

my $init_cols = sub {
    @cols = ();

    # new wrinkle: our input is a series of paths, not a grid
    foreach my $l ( @lines ) {
        next unless $l;
        my @points = ( $l =~ /\b(\d+,\d+)\b/g );

        for ( my $i=0; $i < $#points; $i++ ) {
            my $start = $points[$i];
            my $end = $points[$i + 1];

            my ( $x_s, $y_s ) = split ',', $start;
            my ( $x_e, $y_e ) = split ',', $end;

            if ( $x_s == $x_e ) {
                # change in y - the range operator refusing to go backwards will end me
                my @range = ( $y_s < $y_e ) ? ( $y_s .. $y_e ) : ( $y_e .. $y_s );
                foreach my $y ( @range ) {
                    $set_value->( $x_s, $y, 'r' ); # 'r' for rock
                    # We need to track the largest 'y' value described by the
                    # data. If we move beyond that, we're "falling forever."
                    $max_y = $y if $y > $max_y;
                }
            } else {
                # change in x
                $max_y = $y_s if $y_s > $max_y;
                my @range = ( $x_s < $x_e ) ? ( $x_s .. $x_e ) : ( $x_e .. $x_s );
                foreach my $x ( @range ) {
                    $set_value->( $x, $y_s, 'r' ); # 'r' for rock
                }
            }
        }
    }
#         use Data::Dumper;
#         die Dumper \@cols;
};

my $point_value = sub {
    my ( $x, $y ) = @_;

    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return unless $cols[$x];     # ugh, this would auto-vivify an empty row

    return $cols[$x]->[$y];  # going off the grid is merely undefined
};

my $step_available = sub {
    my ( $x, $y ) = @_;

    return if $y == $max_y + 1;  # floor for Part 2
    return $x + 0 unless $point_value->( $x + 0, $y + 1 );
    return $x - 1 unless $point_value->( $x - 1, $y + 1 );
    return $x + 1 unless $point_value->( $x + 1, $y + 1 );
    return;
};

my $end_sand = sub {
    my ( $x, $y ) = @_;
    return $y == $max_y ? 1 : 0;
};

$init_cols->();
my $step = 0;

my $do_sand = sub {
    while (1) {
        my ( $x, $y ) = ( 500, 0 );  # sand entry point
        while ( my $next_x = $step_available->( $x, $y ) ) {
            # are we falling forever?
            return $step if $end_sand->( $x, $y );

            # keep moving
            $x = $next_x;
            $y = $y + 1;
        }
        # we can't move further; block this point and continue
        $step++;
        $set_value->( $x, $y, 's' ); # 's' for sand
        return $step if $x == 500 && $y == 0;  # entry point blocked
    }
};

printf "Part 1: %s\n", $do_sand->();


# We can pick up where we left off with a different exit condition.
$end_sand = sub { 0 };

printf "Part 2: %s\n", $do_sand->();
