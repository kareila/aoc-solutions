#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 7
# https://adventofcode.com/2021/day/7

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/16,1,2,0,4,2,7,1,2,14/;
# @lines = split "\n", $lines;

# again we only have one line, but it's a CSV
my @crabs = split /,/, $lines[0];

# first, we should determine two things:
# 1. our min and max values (an unoccupied position might be optimal)
# 2. how many crabs are currently at each position

my $min = 0;
my $max = 0;
my %pos;

foreach my $c (@crabs) {
    $min = $c if $c < $min;
    $max = $c if $c > $max;
    $pos{$c}++;
}

# now check every position in the range and see which one is best
# for part one, each step costs one fuel, but in part two that will change
my $fuel;
my $cost = sub { return 1 * $_[0] };

my $minimize = sub {
    foreach my $i ( $min .. $max ) {
        my $f = 0;
        foreach my $c ( keys %pos ) {
            $f += ( $pos{$c} // 0 ) * $cost->( abs( $c - $i ) );
        }
        $fuel = $f unless defined $fuel && $fuel < $f;
    }
};

$minimize->();

printf "Part 1: %s\n", $fuel;


# now we have a more complicated fuel cost calculation...
# NOTE: this takes several seconds to complete on the full data set, so since every
# move will have the same fuel value every time, let's speed things up with caching
my %cache;

$fuel = undef;
$cost = sub {
    my ( $amt ) = @_;
    return $cache{$amt} if defined $cache{$amt};

    my $tot = 0;
    $tot += $_ foreach ( 0 .. $amt );
    $cache{$amt} = $tot;
    return $tot;
};

$minimize->();

printf "Part 2: %s\n", $fuel;
