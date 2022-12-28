#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 2
# https://adventofcode.com/2022/day/2

# Trying the "split on \n" approach today.

local $/ = '';

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my $lines = <$fh>; close $fh;
my @lines = split "\n", $lines;

# Document the input meanings (not actually needed for code)

# my %calls = ( A => 'Rock', B => 'Paper', C => 'Scissors',
#               X => 'Rock', Y => 'Paper', Z => 'Scissors' );

my $score_shape = sub {
    # 1 for X, 2 for Y, and 3 for Z
    my ( $line ) = @_;
    my ( $lval ) = ( $line =~ /([XYZ])$/ );
    my %score = ( X => 1, Y => 2, Z => 3 );
    return $score{$lval};
};

my $score_round = sub {
    # 0 for loss, 3 for draw, 6 if win
    # there are only nine possible outcomes, just hash them
    my ( $line ) = @_;
    my %score = ( 'A X' => 3, # Rock / Rock
                  'A Y' => 6, # Rock / Paper
                  'A Z' => 0, # Rock / Scissors
                  'B X' => 0, # Paper / Rock
                  'B Y' => 3, # Paper / Paper
                  'B Z' => 6, # Paper / Scissors
                  'C X' => 6, # Scissors / Rock
                  'C Y' => 0, # Scissors / Paper
                  'C Z' => 3, # Scissors / Scissors
    );
    return $score{$line};
};

my $total = 0;

foreach my $l ( @lines ) {
    next unless $l;
    $total += $score_shape->($l);
    $total += $score_round->($l);
}

printf "Part 1: %s\n", $total;

# New meaning for XYZ!
# my %calls = ( A => 'Rock', B => 'Paper', C => 'Scissors',
#               X => 'lose', Y => 'draw',  Z => 'win' );

my $choose_play = sub {
    my ( $line ) = @_;
    my ( $opp, $act ) = split ' ', $line;

#     my %lose = qw( A C B A C B );  # one letter lower
#     my %draw = qw( A A B B C C );  # same letter
#     my %win_ = qw( A B B C C A );  # one letter higher
#
#     my $choice;
#
#     $choice = $lose{$opp} if $act eq 'X';
#     $choice = $draw{$opp} if $act eq 'Y';
#     $choice = $win_{$opp} if $act eq 'Z';

    # the above can be rewritten as a single expression
    my $choice = {
            X => { qw( A C B A C B ) },  # lose: one letter lower
            Y => { qw( A A B B C C ) },  # draw: same letter
            Z => { qw( A B B C C A ) },  # win: one letter higher
        }->{$act}->{$opp};

    # map to old meaning for scorer subroutines
    my %convert = qw( A X B Y C Z );
    return sprintf( "%s %s", $opp, $convert{$choice} );
};

$total = 0;

# @lines = ( 'A Y', 'B X', 'C Z' );  # confirm this returns 12

foreach my $l ( @lines ) {
    next unless $l;
    my $c = $choose_play->($l);
    $total += $score_shape->($c);
    $total += $score_round->($c);
}

printf "Part 2: %s\n", $total;
