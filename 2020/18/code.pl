#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2020, Day 18
# https://adventofcode.com/2020/day/18

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# example data
# my $lines = q/
# 1 + 2 * 3 + 4 * 5 + 6
# 1 + (2 * 3) + (4 * (5 + 6))
# 2 * 3 + (4 * 5)
# 5 + (8 * 3 + 9 + 3 * 4 * 3)
# 5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))
# ((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2
# 3 + 3 * (5 + (7 * 5 + 4 * 8 + 9 * 2) + 3) * 8 * 7
# /;
# @lines = grep { length $_ } split "\n", $lines;

my $check_op = sub { 0 };  # used in Part 2

my $calculate = sub {
    my ( $s1, $op, $s2 ) = @_;
    my ( $open, $n1 ) = ( $s1 =~ /^([(]*)(\d+)$/ );
    my ( $n2, $shut ) = ( $s2 =~ /^(\d+)([)]*)$/ );
    die "Something is very wrong" unless defined $n1;

    my $result;
    $result = $n1 + $n2 if $op eq '+';
    $result = $n1 * $n2 if $op eq '*';
    die "Unknown operation $op" unless defined $result;

    return sprintf "%s%s%s", $open // '', $result, $shut // '';
};

my $evaluate = sub {
    my ( $l ) = @_;
    my @exp = split ' ', $l;
    my @stack;

    # return true so we can do "and next"
    my $dump_stack = sub { unshift @exp, @stack; @stack = (); 1 };
    my $use_stack = sub { unshift @exp, pop; push @stack, @_; 1 };

    # execute from left to right, stacking when we encounter parens
    while ( 1 ) {
        # if we reached the end, dump the stack, or exit if there isn't one
        if ( scalar @exp == 1 ) {
            @stack ? $dump_stack->() : last;
        }

        my ( $n1, $op, $n2 ) = splice @exp, 0, 3;
        die "Something is very wrong" unless defined $n2;

        # if n2 starts a new parenthetical, stack and continue
        if ( $n2 =~ /^[(]/ ) {
            $use_stack->( $n1, $op, $n2 ) and next;
        }

        # if n1 and n2 complete a parenthetical, remove parens and calculate
        if ( $n1 =~ /^[(]/ && $n2 =~ /[)]$/ ) {
            $n1 =~ s/^[(]//;
            $n2 =~ s/[)]$//;
            unshift @exp, $calculate->( $n1, $op, $n2 );
            $dump_stack->() and next;
        }

        # in Part 2, we get operator precedence rules
        if ( $check_op->( $op, @exp ) ) {
            $use_stack->( $n1, $op, $n2 ) and next;
        }

        # nothing needs to be stacked
        unshift @exp, $calculate->( $n1, $op, $n2 );

        # start over from the beginning unless we're continuing an open paren
        $dump_stack->() unless $n1 =~ /^[(]/;
    }
    return $exp[0];
};

my $sum = 0;
$sum += $evaluate->($_) foreach @lines;

printf "Part 1: %s\n", $sum;


# now do all additions before multiplications
# return true if we need to stack this for now
$check_op = sub {
    my ( $op, @exp ) = @_;
    return 0 if $op eq '+';   # we are adding
    my $s = join '', @exp;
    return 0 if $s !~ /[+]/;  # no more additions

    # there are additions, but do we have a close paren first?
    my $par = index $s, ')';
    my $add = index $s, '+';
    return 1 if $par == -1;   # no close parens
    return 0 if $par < $add;  # closed before addition
    return 1;                 # addition before close
};

$sum = 0;
$sum += $evaluate->($_) foreach @lines;

printf "Part 2: %s\n", $sum;
