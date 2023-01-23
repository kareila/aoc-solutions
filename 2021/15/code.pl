#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 15
# https://adventofcode.com/2021/day/15

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 1163751742
# 1381373672
# 2136511328
# 3694931569
# 7463417111
# 1319128137
# 1359912421
# 3125421639
# 1293138521
# 2311944581
# /;
# @lines = grep { length $_ } split "\n", $lines;

my @rows = map { [ split '' ] } @lines;

my $point_value = sub {
    my ( $x, $y ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return unless $rows[$y];     # ugh, this would auto-vivify an empty row
    return $rows[$y]->[$x];      # going off the grid is merely undefined
};

my $coord = sub { return join ',', @{ $_[0] } };

my $neighbors = sub {
    my ( $pos ) = @_;
    my ( $x, $y ) = split ',', $pos;
    my %ret;

    foreach my $p ( [ $x-1, $y ], [ $x+1, $y ], [ $x, $y-1 ], [ $x, $y+1 ] ) {
        my $v = $point_value->(@$p);
        next unless defined $v;
        $ret{ $coord->($p) } = $v;
    }

    return %ret;
};

# finding the minimum is faster than keeping an entire list sorted
my $min = sub {
    my %vals = @_;
    my @list = keys %vals;
    my $min = shift @list;
    foreach ( @list ) { $min = $_ if $_ < $min; }
    return $vals{$min};
};

my $dijkstra = sub {
    my %n = $neighbors->('0,0');
    my %picked = ( '0,0' => 1 );
    my %dist = %n;

    # we are told our grid is a square
    my $end = join ',', $#rows, $#rows;

    while ( 1 ) {
        # keep picking the next closest point until we reach the end
        my $pick = $min->( map { $dist{$_} => $_ } keys %n );
        delete $n{$pick};
        $picked{$pick}++;
        my %pn = $neighbors->($pick);

        while ( my ( $p, $v ) = each %pn ) {
            next if $picked{$p};
            my $d = $v + $dist{$pick};
            $dist{$p} = $d unless defined $dist{$p} && $dist{$p} < $d;
            $n{$p} = $v;
            return $dist{$p} if $p eq $end;
        }
    }
};

printf "Part 1: %s\n", $dijkstra->();


# For Part 2, we don't have to change our logic, just the underlying grid.
my $tile_size = scalar @rows;

for ( my $m=0; $m < 5; $m++ ) {
    for ( my $n=0; $n < 5; $n++ ) {
        for ( my $j=0; $j < $tile_size; $j++ ) {
            my $y = $j + $tile_size * $m;
            for ( my $i=0; $i < $tile_size; $i++ ) {
                my $x = $i + $tile_size * $n;
                $rows[$y]->[$x] = ( $rows[$j]->[$i] + $m + $n - 1 ) % 9 + 1;
            }
        }
    }
}

# die join "\n", map { join '', @$_ } @rows;

printf "Part 2: %s\n", $dijkstra->();

# This takes a somewhat long time to complete (~33 seconds) on a 500x500 grid.
# Not sure if there's a way to further optimize the performance of this method
# apart from using a heap instead of my min function on every step. To do that I
# would need to install and use a third party module, which I've avoided so far.
# But it still performs better than my initial draft, which took almost two minutes!
