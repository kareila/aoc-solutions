#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 17
# https://adventofcode.com/2021/day/17

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# target area: x=20..30, y=-10..-5
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $target_bounds = sub {
    my ( $input ) = @_;
    # values of x are always positive; values of y are always negative
    my ( $x1, $x2, $y1, $y2 ) = ( $input =~ /: x=(\d+)..(\d+), y=(-\d+)..(-\d+)$/ );
    return { 'tx_min' => $x1, 'tx_max' => $x2, 'ty_min' => $y1, 'ty_max' => $y2 };
}->( $lines[0] );  # only one line of input

# our max_y can be calculated purely from our initial y velocity
my $max_y = sub { $_[0] * ( $_[0] + 1 ) / 2 };

# this must be true, because math
printf "Part 1: %s\n", $max_y->( $target_bounds->{ty_min} );


my $pos;
my $vel;

my $time_step = sub {
    $pos->[0] += $vel->[0];
    $pos->[1] += $vel->[1];
    $vel->[0] += 1 if $vel->[0] < 0;
    $vel->[0] -= 1 if $vel->[0] > 0;
    $vel->[1] -= 1;
};

my $in_target_area = sub {
    my ( $x, $y ) = @_;
    return 0 if $x < $target_bounds->{tx_min} || $x > $target_bounds->{tx_max};
    return 0 if $y < $target_bounds->{ty_min} || $y > $target_bounds->{ty_max};
    return 1;
};

my $check_trajectory = sub {
    my ( $vx, $vy ) = @_;
    $vel = [ $vx, $vy ];
    $pos = [0,0];

    # y_limit is the "minimum" because the target is below us
    my $x_limit = $target_bounds->{tx_max};
    my $y_limit = $target_bounds->{ty_min};
    my $prev;

    while ( $pos->[0] <= $x_limit && $pos->[1] >= $y_limit ) {
        $prev = [ @$pos ];
        $time_step->();
    }

    # loop exits when $pos is past target area - check previous position
    return $in_target_area->( @$prev );
};

# map out our search space based on parameter limits:
# - x velocity must be >= 1 and <= tx_max
# - y velocity must be >= ty_min and <= neg ty_min (see Part 1)
my $count = 0;

for ( my $x = 1; $x <= $target_bounds->{tx_max}; $x++ ) {
    for ( my $y = $target_bounds->{ty_min}; $y <= 0 - $target_bounds->{ty_min}; $y++ ) {
        $count += $check_trajectory->( $x, $y );
    }
}

printf "Part 2: %s\n", $count;
