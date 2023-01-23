#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 9
# https://adventofcode.com/2021/day/9

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# 2199943210
# 3987894921
# 9856789892
# 8767896789
# 9899965678
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @rows;
my @cols;

foreach my $l (@lines) {
    push @rows, [ split '', $l ];
}

for ( my $i=0; $i < length $lines[0]; $i++ ) {
    push @cols, [ map { substr $_, $i, 1 } @lines ];
}

my $point_value = sub {
    my ( $x, $y ) = @_;

    my $max_x = scalar @cols - 1;
    my $max_y = scalar @rows - 1;

    my $max_val = 9;  # not lower than anything

    return $max_val if $x < 0 || $x > $max_x;
    return $max_val if $y < 0 || $y > $max_y;

    return $cols[$x]->[$y];
};

my $is_low_point = sub {
    my ( $x, $y ) = @_;
    my $higher = 4;

    $higher-- if $point_value->( $x, $y ) < $point_value->( $x - 1, $y );
    $higher-- if $point_value->( $x, $y ) < $point_value->( $x + 1, $y );
    $higher-- if $point_value->( $x, $y ) < $point_value->( $x, $y - 1 );
    $higher-- if $point_value->( $x, $y ) < $point_value->( $x, $y + 1 );

    return $higher ? 0 : 1;
};

my @low_points;
my $total_risk = 0;

for ( my $x=0; $x < scalar @cols; $x++ ) {
    for ( my $y=0; $y < scalar @rows; $y++ ) {
        if ( $is_low_point->( $x, $y ) ) {
            push @low_points, [ $x, $y ];
            my $risk = 1 + $point_value->( $x, $y );
            $total_risk += $risk;
        }
    }
}

printf "Part 1: %s\n", $total_risk;


my $keypoint = sub { join '-', @_ };

my $size_basin = sub {
    my @found_points = ( [@_] );
    my %saved_points = ( $keypoint->(@_) => 1 );

    my $check_point = sub {
        # $point_value already returns 9 if we go off the grid, conveniently
        return if $point_value->(@_) == 9;

        push @found_points, [@_] unless $saved_points{ $keypoint->(@_) }++;
    };

    while ( @found_points > 0 ) {
        my ( $x, $y ) = @{ shift @found_points };

        $check_point->( $x - 1, $y );
        $check_point->( $x + 1, $y );
        $check_point->( $x, $y - 1 );
        $check_point->( $x, $y + 1 );
    }

    return scalar keys %saved_points;
};

my @sizes = sort { $b <=> $a } map { $size_basin->(@$_) } @low_points;
my $result = $sizes[0] * $sizes[1] * $sizes[2];

printf "Part 2: %s\n", $result;
