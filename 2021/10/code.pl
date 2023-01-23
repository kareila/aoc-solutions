#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2021, Day 10
# https://adventofcode.com/2021/day/10

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# [({(<(())[]>[[{[]{<()<>>
# [(()[<>])]({[<{<<[]>>(
# {([(<{}[<>[]}>{[]{[(<()>
# (((({<>}<{<{<>}{[]{[]{}
# [[<[([]))<([[{}[[()]]]
# [{[{({}]{}}([{[{{{}}([]
# {<[[]]>}<{[{[{[]{()[[[]
# [<(<(<(<{}))><([]([]()
# <{([([[(<>()){}]>(<<{{
# <{([{{}}[<[[[<>{}]]]>[]]
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $start_chars = '([{<';
my $close_chars = ')]}>';

my $error_score = { ')' => 3, ']' => 57, '}' => 1197, '>' => 25137 };
my $total_score = 0;

my @keep;

LINE:
foreach my $l (@lines) {
    my @stack;

    foreach my $c ( split '', $l ) {
        my $val = index $close_chars, $c;
        if ( $val != -1 ) {
            if ( $val == $stack[-1] ) {
                # found a close character that matches the current start character
                pop @stack;
            } else {
                # found a close character but it doesn't match, calculate score
                $total_score += $error_score->{$c};
                next LINE;
            }
        } else {
            # must be a start character
            push @stack, index $start_chars, $c;
        }
    }

    # finished without errors
    push @keep, \@stack;
}

printf "Part 1: %s\n", $total_score;


# new score values { ')' => 1, ']' => 2, '}' => 3, '>' => 4 } are 1 + index value
my $match_score = sub { return $_[0] + 1 };
my @total_scores;

foreach my $k (@keep) {
    my $score = 0;
    foreach my $v ( reverse @$k ) {
        $score *= 5;
        $score += $match_score->($v);
    }
    push @total_scores, $score;
}

my @sorted = sort { $a <=> $b } @total_scores;
my $middle = $#sorted / 2;

printf "Part 2: %s\n", $sorted[ $middle ];
