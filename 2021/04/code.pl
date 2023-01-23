#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 4
# https://adventofcode.com/2021/day/4

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example code
# my $lines = qq/7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
#
# 22 13 17 11  0
#  8  2 23  4 24
# 21  9 14 16  7
#  6 10  3 18  5
#  1 12 20 15 19
#
#  3 15  0  2 22
#  9 18 13 17  5
# 19  8  7 25 23
# 20 11 10 24  4
# 14 21 16 12  6
#
# 14 21 17 24  4
# 10 16 15  9 19
# 18  8 23 26 20
# 22 11 13  6  5
#  2  0 12  3  7
# /;
# @lines = split "\n", $lines;

# first, read in the data

my $draws = shift @lines;

my @boards;
my $n = -1;
my $i;

foreach my $l (@lines) {

    # first, we'll see a blank line which means to start a new board
    unless ($l) {
        $n++;
        $i = 0;
        next;
    }

    # then we'll see the board rows, which should be split into cols
    # but single digits will have extra space, so we need to account for that
    my @cols = split /\s+/, $l;
    shift @cols if $cols[0] eq '';
    $boards[$n] = [] if $i == 0;
    $boards[$n]->[$i++] = \@cols;
}

# now we need to process the draws

my @draws = split ',', $draws;
my %bingo;
my $b_num;
my $win;

my $done = sub { 1 };
my %bindex = map { $_ => 1 } (0 .. $#boards);

my $find_bingo = sub {
    foreach my $d (@draws) {
        $b_num = $d;
        $bingo{$d} = 1;

        BOARD:
        foreach my $n ( keys %bindex ) {
            my @rows = @{ $boards[$n] };
            foreach my $r (@rows) {
                my $count = 0;
                # we know there are 5 columns in each row
                map { $count += $bingo{$_} // 0 } @$r;
                if ( $count == 5 ) {
                    $win = $n;
                    return if $done->(scalar keys %bindex);
                    # Part 2: if not done, delete this board and keep going
                    delete $bindex{$n};
                    next BOARD;
                }
            }

            # keep going: check for column bingo
            for ( my $i=0; $i < 5; $i++ ) {
                my $count = 0;
                foreach my $r (@rows) {
                    $count += $bingo{ $r->[$i] } // 0;
                }
                if ( $count == 5 ) {
                    $win = $n;
                    return if $done->(scalar keys %bindex);
                    # Part 2: if not done, delete this board and keep going
                    delete $bindex{$n};
                    next BOARD;
                }
            }
        }
    }
};

$find_bingo->();

# exited the loop in a bingo state - $win should have the winning board number
# and $b_num should have the number that was just called

my $calc_score = sub {
    my $score = 0;
    my $board = $boards[$win];

    foreach my $r (@$board) {
        foreach my $v (@$r) {
            $score += $v unless $bingo{$v};
        }
    }

    $score = $score * $b_num;
};

my $score = $calc_score->();

printf "Part 1: %s\n", $score;


# For part two, reuse the same loop but with a different exit condition.

$done = sub { $_[0] == 1 };
%bindex = map { $_ => 1 } (0 .. $#boards);

$find_bingo->();
$score = $calc_score->();

printf "Part 2: %s\n", $score;
