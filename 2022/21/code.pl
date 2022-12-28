#!/usr/bin/perl

use strict;
use warnings;

# Solution to Advent of Code 2022, Day 21
# https://adventofcode.com/2022/day/21

my $file = "input.txt";
open my $fh, $file or die "No file named $file found.\n";
my @lines = <$fh>; close $fh;
map { chomp $_ } @lines;

# Example data:
# my $lines = q(
# root: pppw + sjmn
# dbpl: 5
# cczh: sllz + lgvd
# zczc: 2
# ptdq: humn - dvpt
# dvpt: 3
# lfqf: 4
# humn: 5
# ljgn: 2
# sjmn: drzm * dbpl
# sllz: 4
# pppw: cczh / lfqf
# lgvd: ljgn * ptdq
# drzm: hmdt - zczc
# hmdt: 32
# );
# @lines = grep { length $_ } split "\n", $lines;

my %monkeys;

my $parse_line = sub {
    my ( $l ) = @_;
    my ( $name, $job ) = ( $l =~ /^([^:]+): (.*)$/ );

    my %math = ( '+' => sub { return $_[0] + $_[1] },
                 '-' => sub { return $_[0] - $_[1] },
                 '*' => sub { return $_[0] * $_[1] },
                 '/' => sub { return $_[0] / $_[1] },
               );

    if ( $job =~ /^\d+$/ ) {
        $monkeys{$name} = { num => $job };
    } else {
        my ( $a, $op, $b ) = ( $job =~ /^(\S+) ([-+*\/]) (\S+)$/ );
        die "Parse error" unless exists $math{$op};
        $monkeys{$name} = { a => $a, b => $b, op => $math{$op}, sym => $op };
        # need sym for Part 2
    }
};

$parse_line->($_) foreach @lines;

sub calc {
    my ( $m ) = @_;
    die "No such animal!" unless exists $monkeys{$m};

    return $monkeys{$m}->{num} if exists $monkeys{$m}->{num};
    return $monkeys{$m}->{op}->( calc( $monkeys{$m}->{a} ), calc( $monkeys{$m}->{b} ) );
}

printf "Part 1: %s\n", calc('root');


# New test: root's monkey 'a' answer and monkey 'b' answer must match;
# you must provide the correct answer for 'humn' to make that happen.
#
# First order of business: where in the "tree" is humn? Under root's a, or b?

sub find {
    my ( $branch ) = @_;
    my $m = $branch->[-1];
    die "No such animal!" unless exists $monkeys{$m};

    return $branch if $m eq 'humn';  # found it
    return if exists $monkeys{$m}->{num};  # dead end

    return ( find( [ @$branch, $monkeys{$m}->{a} ] ), find( [ @$branch, $monkeys{$m}->{b} ] ) );
}

my @search = grep { defined $_ } find( ['root'] );
die if @search > 1;  # thankfully not the case

my $humn_branch = $search[0];

# use Data::Dumper;
# die Dumper $humn_branch;

# Unravel the calculations down the branch, starting with root.

my $get_other_answer = sub {
    my ( $i ) = @_;
    my $m = $monkeys{ $humn_branch->[$i] };
    my $other = $m->{a} eq $humn_branch->[ $i+1 ] ? 'b' : 'a';
    return calc( $m->{$other} );
};

my $answer = $get_other_answer->(0);

for ( my $i=1; $i < scalar @$humn_branch - 1; $i++ ) {
    my $m = $monkeys{ $humn_branch->[$i] };
    my $a = $get_other_answer->($i);

    # add and multiply are easy, they don't care about ordering
    $answer = $answer / $a if $m->{sym} eq '*';
    $answer = $answer - $a if $m->{sym} eq '+';

    if ( $humn_branch->[ $i+1 ] eq $m->{a} ) {
        $answer = $a * $answer if $m->{sym} eq '/';
        $answer = $a + $answer if $m->{sym} eq '-';
    } else {
        $answer = $a / $answer if $m->{sym} eq '/';
        $answer = $a - $answer if $m->{sym} eq '-';
    }
}

printf "Part 2: %s\n", $answer;
