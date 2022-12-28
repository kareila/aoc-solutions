#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 5
# https://adventofcode.com/2022/day/5

# FOR SOME INEXPLICABLE REASON the local $/ technique fails on this input
# so from here on out, we're standardizing on array + map chomp

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = qq(
#     [D]
# [N] [C]
# [Z] [M] [P]
#  1   2   3
#
# move 1 from 2 to 1
# move 3 from 1 to 3
# move 2 from 2 to 1
# move 1 from 1 to 2
# );
# @lines = split "\n", $lines;

# first, parse the stacks
my @stacks;

my $parse_stacks = sub {
    my @rows;
    my $num_stacks;

    foreach my $l (@lines) {
        next unless $l;
        push @rows, $l and next if $l =~ /\[/;      # crates
        ( $num_stacks ) = ( $l =~ /\s(\d+)\s*$/ );  # final stack label
        last;                                       # end of crate section
    }

    my $pattern = join ' ', map { '.(.).' } ( 1 .. $num_stacks );

    my $parse_row = sub {
        my ( $r ) = @_;
        my @s = ( $r =~ qr/$pattern/ );  # fixed width pattern for crate stacks
        my $i = 0;

        foreach my $x (@s) {
            $stacks[++$i] //= [];
            next if $x eq ' ';         # no crate at this position
            push @{ $stacks[$i] }, $x;
        }
    };

    $parse_row->($_) foreach @rows;   # from top to bottom
};

$parse_stacks->();

# now, do the moves
my $move_crates = sub {
    my ( $n, $src, $dst ) = @_;
    foreach (1 .. $n) {
        my $x = shift @{ $stacks[$src] };
        unshift @{ $stacks[$dst] }, $x;
    }
};

my $parse_moves = sub {
    foreach my $l (@lines) {
        next unless $l && $l =~ /^move /;
        my @m = ( $l =~ /move (\d+) from (\d+) to (\d+)/ );
        $move_crates->(@m);
    }
};

$parse_moves->();

# Using 'grep defined' skips the unused zero index of the stack array.
my $tops = join '', map { $_->[0] } grep { defined $_ } @stacks;

printf "Part 1: %s\n", $tops;


# reset the stacks to their initial configuration
@stacks = ();

# move multiple crates at once
$move_crates = sub {
    my ( $n, $src, $dst ) = @_;
    my @x;
    push @x, shift @{ $stacks[$src] } foreach (1 .. $n);
    unshift @{ $stacks[$dst] }, @x;
};

# the rest of the procedure is unchanged

$parse_stacks->();
$parse_moves->();

$tops = join '', map { $_->[0] } grep { defined $_ } @stacks;

printf "Part 2: %s\n", $tops;
