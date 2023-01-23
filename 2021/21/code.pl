#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 21
# https://adventofcode.com/2021/day/21

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# Player 1 starting position: 4
# Player 2 starting position: 8
# );
# @lines = grep { length $_ } split "\n", $lines;

my %pawns;
my $init_pawns = sub {
    foreach (@lines) {
        my ( $pnum, $start ) = /^Player (\d+) starting position: (\d+)$/;
        $pawns{$pnum} = $start;
    }
};
$init_pawns->();

my %score = ( 1 => 0, 2 => 0 );
my $winning_score = 1000;

my $track = sub {
    my ( $pnum, $spaces ) = @_;
    my $t_length = 10;
    my $start = $pawns{$pnum};

    my $stop = ( $start + $spaces - 1 ) % $t_length + 1;
    $pawns{$pnum} = $stop;
    $score{$pnum} += $stop;

    return $pnum if $score{$pnum} >= $winning_score;
    return undef;  # no winner yet
};

my $die_value = 0;
my $die_roll = sub { ( ++$die_value - 1 ) % 100 + 1 };

my $take_turn = sub {
    my ( $pnum ) = @_;
    my $roll = 0;
    $roll += $die_roll->() foreach ( 1..3 );
    return $track->( $pnum, $roll );
};

my $current_player = 1;

my $play_game = sub {
    my $winner;
    until ( defined $winner ) {
        $winner = $take_turn->( $current_player );
        $current_player = ( $current_player == 2 ) ? 1 : 2;
    }
    return $current_player;
};

my $calc = sub {
    my $loser = $play_game->();
    return $score{ $loser } * $die_value;
};

printf "Part 1: %s\n", $calc->();


# Now we need to consider parallel universes, each with their
# own version of the game state we were previously tracking with
# %pawns and %score, and count the number of wins. I tried doing
# this working forward with state dictionaries across different
# positions, but ultimately a purely recursive approach won out.

$winning_score = 21;

$init_pawns->();

# pre-calculate the sums from 1+1+1 to 3+3+3, and how many times each sum occurs
my @quantum_rolls = ( [3,1], [9,1], [4,3], [8,3], [5,6], [7,6], [6,7] );

$track = sub {
    my ( $start, $spaces ) = @_;
    my $t_length = 10;
    my $stop = ( $start + $spaces - 1 ) % $t_length + 1;
    return $stop;
};

my %cache;

sub play_game {
    my ( $pawn1, $score1, $pawn2, $score2 ) = @_;
    return ( 0, 1 ) if $score2 >= $winning_score;
    return ( 1, 0 ) if $score1 >= $winning_score;  # for symmetry, but this
                                                   #  will never be true...
    my $ckey = join '-', @_;
    return @{ $cache{$ckey} } if exists $cache{$ckey};

    my ( $wins1, $wins2 ) = ( 0, 0 );

    foreach my $roll ( @quantum_rolls ) {
        my $new_pos = $track->( $pawn1, $roll->[0] );
        my $new_score = $score1 + $new_pos;

        my ( $w2, $w1 ) = play_game( $pawn2, $score2, $new_pos, $new_score );

        $wins1 += $w1 * $roll->[1];
        $wins2 += $w2 * $roll->[1];
    }
    $cache{$ckey} = [ $wins1, $wins2 ];
    return ( $wins1, $wins2 );
}

my @tot_wins = sort { $b <=> $a } play_game( $pawns{1}, 0, $pawns{2}, 0 );

printf "Part 2: %s\n", $tot_wins[0];
