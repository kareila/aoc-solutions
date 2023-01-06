#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 22
# https://adventofcode.com/2020/day/22

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# Player 1:
# 9
# 2
# 6
# 3
# 1
#
# Player 2:
# 5
# 8
# 4
# 7
# 10
# /;
# @lines = grep { length $_ } split "\n", $lines;

my %deck;  # input data

my $init_deck = sub {
    my $current_player;
    %deck = ();

    foreach ( @lines ) {
        next unless length $_;
        if ( /^Player (\d+):$/ ) {
            $current_player = $1;
            $deck{ $current_player } = [];
            next;
        }
        die "No current player number" unless defined $current_player;

        # we removed blank lines, so all other lines are layout data
        push @{ $deck{ $current_player } }, $_ + 0;
    }
};

$init_deck->();

my $play_round = sub {
    my $card_1 = shift @{ $deck{1} };
    return 2 unless defined $card_1;  # player 2 has all the cards

    my $card_2 = shift @{ $deck{2} };
    return 1 unless defined $card_2;  # player 1 has all the cards

    # no ties are possible
    my $winner = $card_1 > $card_2 ? 1 : 2;
    my @bottom = ( $winner == 1 ) ? ( $card_1, $card_2 ) : ( $card_2, $card_1 );

    push @{ $deck{ $winner } }, @bottom;
    return;  # play continues
};

my $victor;
$victor = $play_round->() until defined $victor;

my $score = sub {
    my $stack = $deck{ $victor };
    my $sum = 0;
    my $mult = 1;

    foreach my $card ( reverse @$stack ) {
        $sum += $mult++ * $card;
    }
    return $sum;
};

printf "Part 1: %s\n", $score->();


$init_deck->();

# Now we need a recursable play function that takes a sub-deck as an argument.
# We also need a cache to check if we've seen the current game state before.

my $game_state = sub {
    my ( $deck ) = @_;
    return join '|', join( ',', @{ $deck->{1} } ), join( ',', @{ $deck->{2} } );
};

my $play_game = sub {
    my ( $cards ) = @_;
    my %states;
    my $victor;

    until ( defined $victor ) {
        my $current_state = $game_state->( $cards );
        return 1 if $states{ $current_state };
        $states{ $current_state }++;

        $victor = $play_round->( $cards );
    }
    return $victor;
};

# Modify play_round to include recursion condition.
$play_round = sub {
    my ( $deck ) = @_;

    my $card_1 = shift @{ $deck->{1} };
    return 2 unless defined $card_1;  # player 2 has all the cards

    my $card_2 = shift @{ $deck->{2} };
    return 1 unless defined $card_2;  # player 1 has all the cards

    # no ties are possible
    my $winner = $card_1 > $card_2 ? 1 : 2;

    my $num_remaining_1 = scalar @{ $deck->{1} };
    my $num_remaining_2 = scalar @{ $deck->{2} };

    # do we recurse? (the quantity of cards copied is equal to
    # the number on the card they drew to trigger the sub-game)
    if ( $num_remaining_1 >= $card_1 && $num_remaining_2 >= $card_2 ) {
        my $subdeck = {
            1 => [ @{ $deck->{1} }[ 0 .. $card_1 - 1 ] ],
            2 => [ @{ $deck->{2} }[ 0 .. $card_2 - 1 ] ],
        };
        $winner = $play_game->( $subdeck );
    }

    my @bottom = ( $winner == 1 ) ? ( $card_1, $card_2 ) : ( $card_2, $card_1 );
    push @{ $deck->{ $winner } }, @bottom;
    return;  # play continues
};

$victor = $play_game->( \%deck );

printf "Part 2: %s\n", $score->();
