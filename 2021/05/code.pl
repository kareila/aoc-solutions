#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 5
# https://adventofcode.com/2021/day/5

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } grep { length $_ } @lines;

# example code
# my $lines = qq/
# 0,9 -> 5,9
# 8,0 -> 0,8
# 9,4 -> 3,4
# 2,2 -> 2,1
# 7,0 -> 7,4
# 6,4 -> 2,0
# 0,9 -> 2,9
# 3,4 -> 1,4
# 0,0 -> 8,8
# 5,5 -> 8,2
# /;
# @lines = split "\n", $lines;

my %points;

my $mark_point = sub {
    my ( $x, $y ) = @_;
    $points{$x}->{$y}++;
};

my $find_overlaps = sub {
    my $total = 0;

    foreach my $x ( keys %points ) {
        foreach my $y ( keys %{ $points{$x} } ) {
            $total++ if $points{$x}->{$y} > 1;
        }
    }

    return $total;
};

foreach my $l (@lines) {
    my ( $x1, $y1, $x2, $y2 ) = ( $l =~ /^(\d+),(\d+) -> (\d+),(\d+)$/ );

    # vertical lines
    if ( $x1 == $x2 ) {
        my ( $s, $e ) = $y1 < $y2 ? ( $y1, $y2 ) : ( $y2, $y1 );

        for ( my $y = $s; $y <= $e; $y++ ) {
            $mark_point->( $x1, $y );
        }
    }

    # horizontal lines
    if ( $y1 == $y2 ) {
        my ( $s, $e ) = $x1 < $x2 ? ( $x1, $x2 ) : ( $x2, $x1 );

        for ( my $x = $s; $x <= $e; $x++ ) {
            $mark_point->( $x, $y1 );
        }
    }
}

printf "Part 1: %s\n", $find_overlaps->();


# Now we need a general purpose version that also handles diagonals.
# I think the key insight here is that for each range of points, X and
# Y both will always either (a) change by one, or (b) stay the same.

%points = ();

my $p_array = sub {
    my ( $x1, $x2, $y1, $y2 ) = @_;

    if ( $x1 == $x2 ) {
        # stay the same
        return map { $x1 } ( 0 .. abs( $y1 - $y2 ) );
    } else {
        # change by one (either up or down)
        # oops, the range operator won't work backwards...
        return $x1 < $x2 ? ( $x1 .. $x2 ) : reverse ( $x2 .. $x1 );
    }
};

foreach my $l (@lines) {
    next unless $l;
    my ( $x1, $y1, $x2, $y2 ) = ( $l =~ /^(\d+),(\d+) -> (\d+),(\d+)$/ );

    my @x = $p_array->( $x1, $x2, $y1, $y2 );
    my @y = $p_array->( $y1, $y2, $x1, $x2 );

    for ( my $i=0; $i <= $#x; $i++ ) {
        $mark_point->( $x[$i], $y[$i] );
    }
}

printf "Part 2: %s\n", $find_overlaps->();
