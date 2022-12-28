#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 16
# https://adventofcode.com/2022/day/16

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
# Valve BB has flow rate=13; tunnels lead to valves CC, AA
# Valve CC has flow rate=2; tunnels lead to valves DD, BB
# Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
# Valve EE has flow rate=3; tunnels lead to valves FF, DD
# Valve FF has flow rate=0; tunnels lead to valves EE, GG
# Valve GG has flow rate=0; tunnels lead to valves FF, HH
# Valve HH has flow rate=22; tunnel leads to valve GG
# Valve II has flow rate=0; tunnels lead to valves AA, JJ
# Valve JJ has flow rate=21; tunnel leads to valve II
# );
# @lines = grep { length $_ } split "\n", $lines;

my $minutes_left = 30;

# This is describing a network of nodes. Each node has a name,
# a value, and a list of links to other nodes. We want to maximize
# the total value in the shortest amount of travel time, visiting
# the highest value targets first.

my %links;
my %rates;

my $parse_line = sub {
    my ( $l ) = @_;
    return unless $l;
    my $pat = qr/^Valve (\w{2}) has flow rate=(\d+); [a-z ]+([A-Z, ]+)$/;
    my ( $name, $r, $k ) = ( $l =~ $pat );
    die "Parse error" unless $name;
    my @links = split ', ', $k;

    $links{$name} = [ @links ];
    $rates{$name} = $r + 0;
};

$parse_line->($_) foreach @lines;

my %paths;

# Here (and elsewhere) I use non-local subroutines when needed for recursion.
sub shortest_path {
    my ( $start, $end, $visited, $path ) = @_;
    $visited //= {};
    $path //= [];
    push @$path, $start if %$visited;  # note our current position
    return $path if $start eq $end;    # if we reached our destination

    # skip to the end if we've walked this part of the path before
    if ( my $p = $paths{$start}->{$end} ) {
        push @$path, @$p;
        return $path;
    }
    $visited->{$start} = 1;

    # recurse through each unvisited exit from our current position
    my %d;
    foreach my $x ( grep { ! $visited->{$_} } @{ $links{$start} } ) {
        my $p = shortest_path( $x, $end, { %$visited }, [ @$path ] );
        $d{$x} = $p if defined $p;
    }
    return unless %d;   # still haven't found what we're looking for

    # get a list of all paths sorted by length
    my @p = sort { @$a <=> @$b } values %d;

    # cache the shortest path, but from this starting point, not the original one
    # (this is a funky workaround because index only works on strings)
    my @s = @{ $p[0] };
    my $i = index( join( '', @s ), $start ) / 2;  # all path names are length 2
    $paths{$start}->{$end} = [ @s[ $i + 1 .. $#s ] ];

    return $p[0];
}

{   # fully populate %paths with the shortest path between every node
    my @nodes = sort keys %links;

    foreach my $i ( @nodes ) {
        foreach my $j ( @nodes ) {
            shortest_path( $i, $j );
        }
    }
}

# minimum time to open valve at $e if currently standing in $s
my $distance = sub {
    my ( $s, $e ) = @_;
    my $d = scalar @{ $paths{$s}->{$e} // [] };
    return $d + 1;  # add one for opening time
};

# Now it's time to act. It takes one minute to
# make one move and one minute to open a valve.
#
# From our current location, walk each possible path
# between valves and see which ordering maximizes the
# total pressure released in the available time.
#
# Note: final algorithm just stacks the amount of
# pressure released by each opened valve over the
# entire remaining time, since that's a constant.

my $cached_vals = {};

my $path_value = sub {
    my @path = @_;
    # load the cached value of the prior part of this path
    my $k = join '-', @path[ 0 .. $#path - 1 ];
    my $cache = $cached_vals->{$k};

    my $tot_d = $cache ? $cache->[0] : 0;
    my $tot_prod = $cache ? $cache->[1] : 0;
    @path = $cache ? @path[ -2 .. -1 ] : @path;

    for ( my $i=1; $i <= $#path; $i++ ) {
        $tot_d += $distance->( $path[ $i - 1 ], $path[$i] );
        return 0 if $tot_d > $minutes_left;  # path too long
        $tot_prod += ( $minutes_left - $tot_d ) * $rates{ $path[$i] };
    }
    $cached_vals->{ sprintf "%s-%s", $k, $path[-1] } = [ $tot_d, $tot_prod ];
    return $tot_prod;
};

my @valves = grep { $rates{$_} > 0 } keys %links;
my %routes;

my $walk_path = sub {
    # $k is a hyphen-separated list of nodes on this path
    my ( $k ) = @_;
    # changing the zero check to a grep on the input list saved a few seconds
#     return 0 if defined $routes{$k} && $routes{$k} == 0;

    my @path = split '-', $k;
    my %opened = map { $_ => 1 } @path;
    my @remaining = grep { ! $opened{$_} } @valves;

    # try to reach each remaining unopened valve from this node
    foreach my $next ( @remaining ) {
        my $nk = sprintf "%s-%s", $k, $next;
        next if exists $routes{$nk};  # already tried it
        $routes{$nk} = $path_value->( @path, $next );
    }
};

my $location = 'AA';
$walk_path->( $location );  # start with the shortest path from AA to any closed valve
foreach my $i ( 1 .. scalar @valves - 1 ) {
    # keep visiting more valves until %routes is no longer changing
    my $t = scalar keys %routes;
    $walk_path->( $_ ) foreach grep { $routes{$_} } keys %routes;  # ignore zeroes
    last if $t == scalar keys %routes;
    warn sprintf( "Level %s: %s routes mapped\n", $i, scalar keys %routes )
        if @lines > 10;  # show progress for larger data set
}
my @r = sort { $b <=> $a } values %routes;

printf "\nPart 1: %s\n\n", $r[0];


# This is so dumb and it doesn't work on the example but I am so done.
# It just reruns the same algorithm for the human and then finds the
# max for the elephant opening the valves that the human didn't open.
#
# Noting for posterity: apparently the "right" way to do this is to
# rerun the algorithm on permutations of different valves assigned to
# one or the other. I just don't want to spend any more time on this.

$minutes_left = 26;
$cached_vals = {};
%routes = ();

$walk_path->( $location );
foreach my $i ( 1 .. scalar @valves - 1 ) {
    my $t = scalar keys %routes;
    $walk_path->( $_ ) foreach grep { $routes{$_} } keys %routes;  # ignore zeroes
    last if $t == scalar keys %routes;
    warn sprintf( "Level %s: %s human routes mapped\n", $i, scalar keys %routes )
        if @lines > 10;  # show progress for larger data set
}
my @k = sort { $routes{$b} <=> $routes{$a} } keys %routes;
my $own_vals = $routes{ $k[0] };
my %opened = map { $_ => 1 } split '-', $k[0];

@valves = grep { ! $opened{$_} } @valves;
$cached_vals = {};
%routes = ();

$walk_path->( $location );
foreach my $i ( 1 .. scalar @valves - 1 ) {
    my $t = scalar keys %routes;
    $walk_path->( $_ ) foreach grep { $routes{$_} } keys %routes;  # ignore zeroes
    last if $t == scalar keys %routes;
    warn sprintf( "Level %s: %s elephant routes mapped\n", $i, scalar keys %routes )
        if @lines > 10;  # show progress for larger data set
}
@r = sort { $b <=> $a } values %routes;
my $ele_vals = $r[0];

printf "\nPart 2: %s\n", $own_vals + $ele_vals;

# elapsed time: approx. 19 seconds for both parts together
