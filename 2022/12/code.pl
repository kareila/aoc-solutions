#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 12
# https://adventofcode.com/2022/day/12

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Sabqponm
# abcryxxl
# accszExk
# acctuvwj
# abdefghi
# );
# @lines = grep { length $_ } split "\n", $lines;

my @rows;
my $init_rows = sub { @rows = (); push @rows, [ split '', $_ ] foreach @lines };
$init_rows->();

my $point_value = sub {
    my ( $x, $y ) = @_;
    ( $x, $y ) = @$x if ref $x;  # allow arrayref arguments for simplicity's sake

    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array
    return unless $rows[$y];     # ugh, this would auto-vivify an empty row

    return $rows[$y]->[$x];  # going off the grid is merely undefined
};

my %visited;
my $was_visited = sub { $visited{ join '-', @_  } };
my $set_visited = sub { $visited{ join '-', @_  } = 1 };

my $next_step = sub {
    my ( $current ) = @_;
    my ( $x, $y ) = @$current;
    my $v = $point_value->( $x, $y );
    $v = 'a' if $v eq 'S';  # starting point has 'a' value

    # 0. Since we're exploring in parallel, abort if our current
    #    location has been marked as visited by another path.
    return [] if $was_visited->( $x, $y );

    # 1. Mark that you've visited your current location.
    $set_visited->( $x, $y );

    # 2. Look at the possible steps up, down, left or right (no diagonals)
    #    and see if any of them are (a) off the grid, (b) already visited,
    #    or (c) our destination.
    my @possible;

    foreach my $p ( [ $x-1, $y ], [ $x+1, $y ], [ $x, $y-1 ], [ $x, $y+1 ] ) {
        my $pv = $point_value->(@$p);
        next unless defined $pv;
        next if $was_visited->(@$p);

        if ( $pv eq 'E' ) {
            # are we high enough?
            return [ $p ] if { 'y' => 1, 'z' => 1 }->{$v};
            # sadly, no - treat this like any other z value
            $pv = 'z';
        }

        # 3. A step is possible if it is no more than one level higher.
        my $map_index = 'abcdefghijklmnopqrstuvwxyz';
        my $e_next = index $map_index, $pv;
        my $e_curr = index $map_index, $v;
        push @possible, $p if $e_next <= $e_curr + 1;  # e is for elevation
    }

    # If this is a dead end, the result is an empty list.
    return [ @possible ];
};

my %start_values = ( S => 1 );

my $start_paths = sub {
    my @start;

    for ( my $j=0; $j <= $#lines; $j++ ) {
        for ( my $i=0; $i < length $lines[$j]; $i++ ) {
            my $v = $point_value->( $i, $j );
            push @start, [ [ $i, $j ] ] if $start_values{$v};
        }
    }
    return @start;
};

my $walk_map = sub {
    # First order of business, find the starting point(s).
    my @paths = $start_paths->();
    die "No start found" unless @paths;
    %visited = ();

    # If we abandon a trail, we need to ignore it on future passes.
    my @culls;
    my $do_culls = sub {
        splice( @paths, $_, 1 ) foreach reverse @culls;
        @culls = ();
    };

    # Start evaluating next steps. If more than one is possible, branch out.
    # Explore all paths in parallel! The first one completed is the shortest.
    while ( 1 ) {
        $do_culls->();
        my $pnum = $#paths;  # cache this, the value changes as we push new paths
        for ( my $pi = 0; $pi <= $pnum; $pi++ ) {
            my @current = @{ $paths[$pi] };
            my $next = $next_step->( $current[-1] );

# use Data::Dumper;
# warn Dumper [ @paths[-2..-1] ];
# use Term::ReadLine;
# my $term = Term::ReadLine->new('');
# $term->readline("Press return");

            if ( scalar @$next == 0 ) {
                # Dead end. Make sure we ignore it going forward.
                push @culls, $pi;
                next;
            }

            if ( scalar @$next == 1 ) {
                # Only one possible next step. Did we find the exit?
                return scalar @current if $point_value->( $next->[0] ) eq 'E';
            }

            # Explore all possible paths.
            $paths[$pi] = [ @current, shift @$next ];
            push @paths, [ @current, $_ ] foreach @$next;
        }
    }
};

printf "Part 1: %s\n", $walk_map->();


# For Part 2, do the same calculation starting from every 'a' on the grid!

%start_values = ( S => 1, a => 1 );

printf "Part 2: %s\n", $walk_map->();
