#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 9
# https://adventofcode.com/2020/day/9

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = qq/
# 35
# 20
# 15
# 25
# 47
# 40
# 62
# 55
# 65
# 95
# 102
# 117
# 150
# 182
# 127
# 219
# 299
# 277
# 309
# 576
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $window_length = 25;
# $window_length = 5;  # example uses 5

my @window = @lines[ 0 .. $window_length - 1 ];

my $calc = sub {
    my ( $num ) = @_;
    my @data = @window;
    my %sums;

    # build a hash of sums of every combination of two numbers in the window
    while ( @data > 1 ) {
        my $add = shift @data;
        $sums{ $add + $_ }++ foreach @data;
    }
    return exists $sums{ $num } ? 1 : 0;
};

my $num_invalid = sub {
    for ( my $i = $window_length; $i < @lines; $i++ ) {
        my $test_num = $lines[$i];
        return $test_num unless $calc->( $test_num );

        # adjust the window and continue
        shift @window;
        push @window, $test_num;
    }
}->();

printf "Part 1: %s\n", $num_invalid;


# find a contiguous set of at least two numbers in the list which sum to $num_invalid

$calc = sub {
    my ( $sum, $i ) = ( 0, 0 );
    return if $lines[0] == $num_invalid;  # at least two numbers

    $sum += $lines[$i++] while $sum < $num_invalid;
    return $sum == $num_invalid ? $i - 1 : undef;
};

my $index = sub {
    while ( @lines ) {
        my $found = $calc->();  # modify @lines instead of passing function arguments
        return $found if $found;
        shift @lines;
    }
}->();

die "No index found!" unless defined $index;

my @result = sort { $a <=> $b } @lines[ 0 .. $index ];

printf "Part 2: %s\n", $result[0] + $result[-1];
