#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 14
# https://adventofcode.com/2021/day/14

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# NNCB
#
# CH -> B
# HH -> N
# CB -> H
# NH -> C
# HB -> C
# HC -> B
# HN -> C
# NN -> C
# BH -> H
# NC -> B
# NB -> B
# BN -> B
# BB -> N
# BC -> B
# CC -> N
# CN -> C
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $start = $lines[0];
my @rules = grep { /->/ } @lines;

my %insert;

foreach (@rules) {
    my ( $pair, $ins ) = split / -> /;
    my ( $a, $b ) = split '', $pair;
    $insert{$pair} = join '', $a, $ins, $b;
}

my $do_insertion = sub {
    my $pos = length($start) - 1;
    while ( $pos-- > 0 ) {
        my $pair = substr $start, $pos, 2;
        substr $start, $pos, 2, $insert{$pair};
    }
};

$do_insertion->() foreach ( 1 .. 10 );

my $find_q = sub {
    my %freq;
    $freq{$_}++ foreach split '', $start;
    my @sorted = sort { $freq{$b} <=> $freq{$a} } keys %freq;
    return $freq{ $sorted[0] } - $freq{ $sorted[-1] };
};

printf "Part 1: %s\n", $find_q->();


# We can't just keep churning - the string gets too long to handle after 16 steps.
# Instead, let's just track the numbers of each pair over time.

my %pair_rules;

foreach (@rules) {
    my ( $pair, $ins ) = split / -> /;
    my ( $a, $b ) = split '', $pair;
    $pair_rules{$pair} = [ "$a$ins", "$ins$b" ];
}

my %s_pairs;

{
    my $pos = length($start) - 1;
    while ( $pos-- > 0 ) {
        my $pair = substr $start, $pos, 2;
        $s_pairs{$pair}++;
    }
}

$do_insertion = sub {
    my %n_pairs;
    foreach my $p ( keys %s_pairs ) {
        my @new = $pair_rules{$p} ? @{ $pair_rules{$p} } : ( $p );
        $n_pairs{$_} += $s_pairs{$p} foreach @new;
    }
    %s_pairs = %n_pairs;
};

$do_insertion->() foreach ( 11 .. 40 );

$find_q = sub {
    my %freq;
    foreach my $p ( keys %s_pairs ) {
        # count the first element of each pair, since pairs overlap
        my $s = substr $p, 0, 1;
        $freq{$s} += $s_pairs{$p};
    }
    # the last char of the string is the odd one out, don't forget to count it
    my $end = substr $start, -1, 1;
    $freq{$end}++;

    my @sorted = sort { $freq{$b} <=> $freq{$a} } keys %freq;
    return $freq{ $sorted[0] } - $freq{ $sorted[-1] };
};

printf "Part 2: %s\n", $find_q->();
