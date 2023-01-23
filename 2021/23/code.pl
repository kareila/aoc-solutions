#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 23
# https://adventofcode.com/2021/day/23

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# #############
# #...........#
# ###B#C#B#D###
#   #A#D#C#A#
#   #########
# );
# @lines = grep { length $_ } split "\n", $lines;

my @start_rooms;

my $init_rooms = sub {
    @start_rooms = ( [], [], [], [] );

    # translate occupant values to numerics, which also correspond
    # to the power of ten that it costs for them to move one step
    my $occ_num = sub { index 'ABCD', $_[0] };

    foreach (@lines) {
        next unless /#(\w)#(\w)#(\w)#(\w)#/;
        my @occ = ( $1, $2, $3, $4 );
        for ( my $i=0; $i < 4; $i++ ) {
            push @{ $start_rooms[$i] }, $occ_num->( $occ[$i] );
        }
    }
};
$init_rooms->();

# Ugh, these brute-force "minimum of all possible solutions" exercises
# are my least favorite, so I'm going to skip straight to my usual guide:
# https://github.com/mebeim/aoc/tree/master/2021#day-23---amphipod

my @start_hallway = map { undef } (1..7);  # only usable spaces
my $room_size = 2;

# step counts
my @hall_costs = ( [ 2, 1, 1, 3, 5, 7, 8 ], [ 4, 3, 1, 1, 3, 5, 6 ] );
push @hall_costs, [ reverse @{ $hall_costs[1] } ];
push @hall_costs, [ reverse @{ $hall_costs[0] } ];

my $move_cost = sub {
    my ( $room, $hallway, $ri, $hi, $to_room ) = @_;
    my ( $start, $end );

#     hallway spots:  0 | 1 | 2 | 3 | 4 | 5 | 6
#                           ^   ^   ^   ^
#     rooms:                0   1   2   3

    # order hallway endpoints from left to right
    # if to_room is true, omit this target's current position at hallway[hi]
    if ( $ri + 1 < $hi ) {
        ( $start, $end ) = ( $ri + 2, $hi + ( $to_room ? -1 : 0 ) );
    } else {
        ( $start, $end ) = ( $hi + ( $to_room ? 1 : 0 ), $ri + 1 );
    }

    # bail out if the hallway isn't clear
    return undef if $start <= $end && grep { defined $_ } @{ $hallway }[ $start .. $end ];

    # current target is either at hallway[hi] or room[0]
    my $t = $to_room ? $hallway->[$hi] : $room->[0];
    my $d = $hall_costs[$ri]->[$hi] + ( $to_room // 0 ) + $room_size - scalar @$room;
    die if @$hallway > 7;  # debug hallway indexing
    return ( 10 ** $t ) * $d;
};

# enumerate possible room moves for every occupant of the hallway
my $moves_to_room = sub {
    my ( $rooms, $hallway ) = @_;
    my @possible;

    for ( my $i = 0; $i < @$hallway; $i++ ) {
        my $h = $hallway->[$i];
        next unless defined $h;  # unoccupied
        my $dest = $rooms->[$h];
        next if grep { $_ ne $h } @$dest;  # contains wrong occupant
        my $cost = $move_cost->( $dest, $hallway, $h, $i, 1 );
        next unless defined $cost;
        # Create a new state where this object has been moved to its room,
        # and add the state variables and cost to the list of possibilities.
        my @new_rooms = map { [ @$_ ] } @$rooms;
        my @new_hallway = @$hallway;
        unshift @{ $new_rooms[$h] }, $h;
        $new_hallway[$i] = undef;
        push @possible, [ $cost, \@new_rooms, \@new_hallway ];
    }
    return @possible;
};

# enumerate possible hallway moves for every occupant of every room
my $moves_to_hallway = sub {
    my ( $rooms, $hallway ) = @_;
    my @possible;

    for ( my $ri = 0; $ri < @$rooms; $ri++ ) {
        my $r = $rooms->[$ri];
        next unless grep { $_ ne $ri } @$r;  # only wrong occupants will move
        for ( my $hi = 0; $hi < @$hallway; $hi++ ) {
            my $cost = $move_cost->( $r, $hallway, $ri, $hi );
            next unless defined $cost;
            # Create a new state where this object has moved to this hallway spot,
            # and add the state variables and cost to the list of possibilities.
            my @new_rooms = map { [ @$_ ] } @$rooms;
            my @new_hallway = @$hallway;
            my $o = shift @{ $new_rooms[$ri] };
            $new_hallway[$hi] = $o;
            push @possible, [ $cost, \@new_rooms, \@new_hallway ];
        }
    }
    return @possible;
};

my $possible_moves = sub {
    # whenever we can move someone from the hallway into the room
    # where they belong, that move will always be optimal...
    my @r = $moves_to_room->(@_);
    return $r[0] if @r;
    return $moves_to_hallway->(@_);
};

# Is everyone where they belong?
my $done = sub {
    my ( $rooms ) = @_;
    my $i = 0;
    foreach my $r (@$rooms) {
        return 0 if @$r < $room_size;  # not fully occupied
        return 0 if grep { $_ ne $i } @$r;  # contains wrong occupant(s)
        $i++;
    }
    return 1;  # no failures in foreach
};

# generate static state key for cache use
my $c_key = sub {
    my ( $rooms, $hallway ) = @_;
    my $k = '';
    $k .= join '|', map { join( '-', @$_ ) } @$rooms;
    $k .= ',';
    $k .= join '-', map { $_ // '_' } @$hallway;
    return $k;
};

my %s_cache;

sub solve {
    my ( $rooms, $hallway ) = @_;
    my $ck = $c_key->(@_);
    return $s_cache{$ck} if exists $s_cache{$ck};
    return $s_cache{$ck} = 0 if $done->($rooms);
    my $best;

    foreach my $move ( $possible_moves->(@_) ) {
        my ( $cost, @next ) = @$move;
        $cost += solve(@next);
        if ( ! defined $best || $cost < $best ) {
            $best = $cost;
        }
    }
    return $s_cache{$ck} = $best // 999999999999999;  # impossible
}

printf "Part 1: %s\n", solve( \@start_rooms, \@start_hallway );


# uh oh, new neighbors
splice @lines, 3, 0, ( '  #D#C#B#A#', '  #D#B#A#C#' );
# use Data::Dumper;
# die Dumper \@lines;

$init_rooms->();
$room_size = 4;

printf "Part 2: %s\n", solve( \@start_rooms, \@start_hallway );
# # elapsed time: approx. 5 sec for both parts
