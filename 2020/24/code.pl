#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 24
# https://adventofcode.com/2020/day/24

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# sesenwnenenewseeswwswswwnenewsewsw
# neeenesenwnwwswnenewnwwsewnenwseswesw
# seswneswswsenwwnwse
# nwnwneseeswswnenewneswwnewseswneseene
# swweswneswnenwsewnwneneseenw
# eesenwseswswnenwswnwnwsewwnwsene
# sewnenenenesenwsewnenwwwse
# wenwwweseeeweswwwnwwe
# wsweesenenewnwwnwsenewsenwwsesesenwne
# neeswseenwwswnwswswnw
# nenwswwsewswnenenewsenwsenwnesesenew
# enewnwewneswsewnwswenweswnenwsenwsw
# sweneswneswneneenwnewenewwneswswnese
# swwesenesewenwneswnwwneseswwne
# enesenwswwswneneswsenwnewswseenwsese
# wnwnesenesenenwwnenwsewesewsesesew
# nenewswnwewswnenesenwnesewesw
# eneswnwswnwsenenwnwnwwseeswneewsenese
# neswnwewnwnwseenwseesewsenwsweewe
# wseweeenwnesenwwwswnew
# /;
# @lines = grep { length $_ } split "\n", $lines;

# Okay, the first challenge here is to figure out how to represent
# hex tiles in a grid. I'll use the "odd-r" approach described here:
# https://www.redblobgames.com/grids/hexagons/#coordinates-offset

my $next_coord = sub {
    my ( $dir, $x, $y ) = @_;

    # we are using "pointy-top" orientation with flat "east" and "west"
    return [ $x - 1, $y ] if $dir eq 'w';
    return [ $x + 1, $y ] if $dir eq 'e';

    # alternating rows offset to maintain alignment
    if ( $y % 2 ) {  # odd numbered
        return [ $x + 0, $y + 1 ] if $dir eq 'sw';
        return [ $x + 1, $y + 1 ] if $dir eq 'se';
        return [ $x + 0, $y - 1 ] if $dir eq 'nw';
        return [ $x + 1, $y - 1 ] if $dir eq 'ne';
    } else {  # even numbered
        return [ $x - 1, $y + 1 ] if $dir eq 'sw';
        return [ $x - 0, $y + 1 ] if $dir eq 'se';
        return [ $x - 1, $y - 1 ] if $dir eq 'nw';
        return [ $x - 0, $y - 1 ] if $dir eq 'ne';
    }
    die "invalid direction $dir";
};

# Our reference tile is centered, so use hash keys to avoid negative indices.
my %tiles;

my $flip_tile = sub {
    my ( $p ) = @_;
    die "keys only" unless ! ref $p && $p =~ /,/;
    $tiles{$p} ? delete $tiles{$p} : $tiles{$p}++;
};

foreach (@lines) {
    my @chars = split '';
    my $pos = [0,0];

    while (@chars) {
        my $dir = shift @chars;
        $dir .= shift @chars if { 's' => 1, 'n' => 1 }->{ $dir };
        $pos = $next_coord->( $dir, $pos->[0], $pos->[1] );
    }

    $flip_tile->( join ',', @$pos );
}

printf "Part 1: %s\n", scalar keys %tiles;


# And now we're in a hexagonal Conway game. Of course.
# Our rules depend on the adjacent number of black tiles,
# so we want to examine all black tiles and also all
# white tiles that are adjacent to black tiles.

my %adj_cache;  # reduces computation by a factor of three

my $get_adjacent_coords = sub {
    my ( $p ) = @_;
    die "keys only" unless ! ref $p && $p =~ /,/;
    return @{ $adj_cache{$p} } if $adj_cache{$p};

    my ( $x, $y ) = split ',', $p;
    my @res = ( [ $x - 1, $y ], [ $x + 1, $y ] );

    if ( $y % 2 ) {  # odd numbered
        push @res, ( [ $x, $y + 1 ], [ $x + 1, $y + 1 ] );
        push @res, ( [ $x, $y - 1 ], [ $x + 1, $y - 1 ] );
    } else {  # even numbered
        push @res, ( [ $x, $y + 1 ], [ $x - 1, $y + 1 ] );
        push @res, ( [ $x, $y - 1 ], [ $x - 1, $y - 1 ] );
    }
    $adj_cache{$p} = [ map { join ',', @$_ } @res ];
    return @{ $adj_cache{$p} };
};

my $apply_rules = sub {
    # First, get a list of positions of all black tiles and
    # all tiles of any color adjacent to black tiles. Also,
    # keep a queue of changes to apply them all at the end.
    my ( %inspect, %queue );

    foreach my $p ( keys %tiles ) {
        $inspect{$_}++ foreach ( $get_adjacent_coords->($p), $p );
    }

    foreach my $p ( keys %inspect ) {
        my $num_adj = scalar grep { $tiles{$_} } $get_adjacent_coords->($p);

        if ( $tiles{$p} ) {  # this is a black tile
            $queue{$p}++ if $num_adj == 0;
            $queue{$p}++ if $num_adj > 2;
        } else {  # this is a white tile
            $queue{$p}++ if $num_adj == 2;
        }
    }

    $flip_tile->($_) foreach keys %queue;
};

$apply_rules->() foreach ( 1 .. 100 );

printf "Part 2: %s\n", scalar keys %tiles;
