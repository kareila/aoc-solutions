#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 6
# https://adventofcode.com/2021/day/6

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/3,4,3,1,2/;
# @lines = split "\n", $lines;

# this time we only have one line, but it's a CSV
my @fish = split /,/, $lines[0];

my $iterate = sub {
    my @new;
    for ( my $i=0; $i <= $#fish; $i++ ) {
        $fish[$i]--;
        if ( $fish[$i] < 0 ) {
            $fish[$i] = 6;
            push @new, 8;
        }
    }
    push @fish, @new;
};

my $day = 0;
# $iterate->() while $day++ < 80;

# printf "Part 1: %s\n", scalar @fish;


# We COULD continue from where we left off, except this approach
# quickly runs up against memory allocation issues. So let's only
# track how many fish we have at each age.

my %ages;
$ages{$_}++ foreach @fish;

$iterate = sub {
    # first, decrease every age by one
    for ( my $i=0; $i <= 8; $i++ ) {
        $ages{$i - 1} = $ages{$i};
        $ages{$i} = 0;
    }
    # then, handle reproductions
    if ( $ages{-1} ) {
        $ages{6} += $ages{-1};
        $ages{8}  = $ages{-1};
        delete $ages{-1};
    }
};

$iterate->() while $day++ < 80;

# make sure we get the same result for part one
my $total = 0;
$total += $_ foreach values %ages;

printf "Part 1: %s\n", $total;


# now pick up where we left off
$day--;  # undo the final increment from the previous while loop
$iterate->() while $day++ < 256;

$total = 0;
$total += $_ foreach values %ages;

printf "Part 2: %s\n", $total;
