#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 24
# https://adventofcode.com/2022/day/24

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# #.######
# #>>.<^<#
# #.<..<<#
# #>v.><>#
# #<^v^^>#
# ######.#
# );
# @lines = grep { length $_ } split "\n", $lines;

# Okay. Let's start by getting the size of the grid.

my $max_x = length( $lines[0] ) - 1;
my $max_y = scalar @lines - 1;

my $start_x = index $lines[0], '.';
my $goal_x = index $lines[-1], '.';

# Keep in mind that the wrapping ignores walls, so blizzards
# will travel from 1 to max - 1, or vice versa.
#
# Seems like another max/min scenario (quickest path) similar to Day 12,
# except with pausing and retracing of steps, in order to dodge blizzards.
# But the good news is, we can still remove duplicate paths that end in the
# same spot at the same time, since it doesn't matter how we got there, just
# when we got there. This will let us keep the search space manageable.

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

# The value of a point in the grid occupied by blizzards needs
# to be an arrayref, to allow for multiple blizzards occupying
# the same space at the same time.
#
# Also, to avoid accidentally advancing a blizzard multiple
# times in one turn, set_value should use a temporary working
# grid that gets moved into @rows when completed.

my @work;

my $set_value = sub {
    my ( $x, $y, $v ) = @_;
    return if $x < 0 || $y < 0;  # ugh, this would index the last value of the array

    return $work[$y]->[$x] = $v if ref $v;

    if ( index( '<^v>', $v ) != -1 ) {
        my $p = $work[$y]->[$x] // [];
        my @p = ref $p ? @$p : ($p);  # don't modify @work here
        push @p, $v;
        $v = [ @p ];
    }

    return $work[$y]->[$x] = $v;
};

my $advance_blizzard = sub {
    my ( $x, $y ) = @_;

    my $v = $point_value->( $x, $y );
    return unless defined $v;
    return if ! ref $v && { '.' => 1, '#' => 1 }->{ $v };
    $v = [$v] unless ref $v;

    foreach my $b (@$v) {

        if ( $b eq '<' ) {
            $set_value->( ( $x == 1 ? $max_x : $x ) - 1, $y, '<' ) and next;
        }

        if ( $b eq '>' ) {
            $set_value->( ( $x == $max_x - 1 ? 0 : $x ) + 1, $y, '>' ) and next;
        }

        if ( $b eq '^' ) {
            $set_value->( $x, ( $y == 1 ? $max_y : $y ) - 1, '^' ) and next;
        }

        if ( $b eq 'v' ) {
            $set_value->( $x, ( $y == $max_y - 1 ? 0 : $y ) + 1, 'v' ) and next;
        }

        die "Error parsing grid symbol: $b";  # just in case we did something awful
    }
};

my $minutes = 0;

my $tick = sub {
    for ( my $j = 1; $j < $max_y; $j++ ) {
        for ( my $i = 1; $i < $max_x; $i++ ) {
            $advance_blizzard->( $i, $j );
        }
    }
    for ( my $j = 1; $j < $max_y; $j++ ) {
        for ( my $i = 1; $i < $max_x; $i++ ) {
            $rows[$j]->[$i] = $work[$j]->[$i] // '.';
        }
    }
    @work = ();
    $minutes++;
};

my $view_grid = sub {
    my $p = sub { ref $_[0] ? ( @{ $_[0] } > 1 ? scalar @{ $_[0] } : $_[0]->[0] ) : $_[0] };
    foreach my $r ( @rows ) {
        print join '', map { $p->($_) } @$r;
        print "\n";
    }
};

my $possible_moves = sub {
    my $p = $_[0];
    my ( $x, $y ) = @$p;
    my @opts;

    foreach ( [ $x, $y ], [ $x-1, $y ], [ $x+1, $y ], [ $x, $y-1 ], [ $x, $y+1 ] ) {
        my $v = $point_value->($_);
        push @opts, $_ if defined $v && $v eq '.';
    }
    return @opts;
};

my $goal_point = [ $goal_x, $max_y ];

my $next_step = sub {
    my ( $current ) = @_;
    my @possible = $possible_moves->( $current );

    foreach my $p ( @possible ) {
        # Can we reach our destination?
        my ( $x, $y ) = @$p;
        return [ $p ] if $x == $goal_point->[0] && $y == $goal_point->[1];
    }

    # If this is a dead end, the result is an empty list.
    return [ @possible ];
};

my $start_path = [ [ $start_x, 0 ] ];  # starting point

my $walk_map = sub {
    my @paths = ( $start_path );

    # If we abandon a trail, we need to ignore it on future passes.
    my @culls;
    my $do_culls = sub {
        splice( @paths, $_, 1 ) foreach reverse @culls;
        @culls = ();
    };

    # Start evaluating next steps. If more than one is possible, branch out.
    # Explore all paths in parallel! The first one completed is the shortest.
    while ( 1 ) {
        $tick->();
        $do_culls->();
        my %places;
        my $pnum = $#paths;  # cache this, the value changes as we push new paths
#         warn "Minute $minutes, $pnum active paths...\n";
        for ( my $pi = 0; $pi <= $pnum; $pi++ ) {
            my @current = @{ $paths[$pi] };
            my $c = sprintf "%s,%s", $current[-1]->[0], $current[-1]->[1];
            push @culls, $pi and next if $places{$c}++;  # already here
            my $next = $next_step->( $current[-1] );

            if ( scalar @$next == 0 ) {
                # Dead end. Make sure we ignore it going forward.
                push @culls, $pi and next;
            }

            if ( scalar @$next == 1 ) {
                # Only one possible next step. Did we find the exit?
                my ( $x, $y ) = ( $next->[0]->[0], $next->[0]->[1] );
                return $minutes if $x == $goal_point->[0] && $y == $goal_point->[1];
            }

            # Explore all possible paths. Actually, we don't need
            # to track the entire trail, just the current position.
            $paths[$pi] = [ shift @$next ];
            push @paths, [ $_ ] foreach @$next;
            # (Wow, that one simple change sped things up a lot!)
        }
    }
};

# $view_grid->();
printf "Part 1: %s\n", $walk_map->();


# Keep going! Walk back to the start, then back to the goal.
# Total running time was around 22 sec tracking total path,
# but sped up to about 8 sec just tracking current position.

$start_path = [ [ $goal_x, $max_y ] ];
$goal_point = [ $start_x, 0 ];

$walk_map->();
warn "\nBack to start: $minutes\n\n";

$start_path = [ [ $start_x, 0 ] ];
$goal_point = [ $goal_x, $max_y ];

printf "Part 2: %s\n", $walk_map->();

# elapsed time: approx. 8 sec for both parts together
