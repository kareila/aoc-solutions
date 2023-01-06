#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 13
# https://adventofcode.com/2020/day/13

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 939
# 7,13,x,x,59,x,31,19
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $time_now = $lines[0];
my @ids = split ',', $lines[1];  # don't omit 'x' values here (see Part 2)
my %bus = map { $_ => 0 } grep { $_ ne 'x' } @ids;  # omit them here

foreach my $b ( keys %bus ) {
    $bus{$b} += $b until $bus{$b} >= $time_now;
}

my $soonest = [ sort { $bus{$a} <=> $bus{$b} } keys %bus ]->[0];

printf "Part 1: %s\n", $soonest * ( $bus{ $soonest } - $time_now );


# rewrite %bus to contain index values
for ( my $i=0; $i < @ids; $i++ ) {
    $bus{ $ids[$i] } = $i unless $ids[$i] eq 'x';
}

my $t = 0;

# return a list of bus IDs that are in the correct position at this time
# (at $t=0, the first bus $ids[0] will be the only one in the right place)
my $find_overlaps = sub { grep { ! ( ( $t + $bus{$_} ) % $_ ) } keys %bus };

my $num = 1;
my $skip = $ids[0];  # use this bus as the first skip interval
my %skip_size;

my $update_skips = sub {
    my @which = sort { $a <=> $b } @_;  # sorted output from $find_overlaps
    my $n = scalar @which;
    my $k = join ',', @which;
    $skip_size{$k} //= [];
    push @{ $skip_size{$k} }, $t;

    # Once a specific group of IDs have appeared twice here,
    # take the interval between them and make it the new skip
    # interval if there are more IDs in the right place than before.
    if ( $n > $num && scalar @{ $skip_size{$k} } > 1 ) {
        $skip = $skip_size{$k}->[-1] - $skip_size{$k}->[-2];
        $num = $n;
    }
};

while (1) {
    my @res = $find_overlaps->();
    last if @res == scalar keys %bus;  # all in the correct place
    $update_skips->(@res);
    $t += $skip;
}

printf "Part 2: %s\n", $t;
